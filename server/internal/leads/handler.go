package leads

import (
	"fmt"
	"log"
	"net/http"
	"time"

	"crm-server/internal/models"
	"crm-server/pkg/database"

	"github.com/gin-gonic/gin"
)

// parseFlexDate tries multiple date formats
func parseFlexDate(s string) *time.Time {
	if s == "" {
		return nil
	}
	formats := []string{
		time.RFC3339,
		"2006-01-02T15:04:05Z07:00",
		"2006-01-02T15:04:05.000Z",
		"2006-01-02T15:04:05Z",
		"2006-01-02T15:04:05",
		"2006-01-02",
		"02/01/2006", // DD/MM/YYYY
		"01/02/2006", // MM/DD/YYYY
		"2/1/2006",
		"02-01-2006",
	}
	for _, f := range formats {
		if t, err := time.Parse(f, s); err == nil {
			return &t
		}
	}
	return nil
}

// extractStr safely gets a string from a map (handles any type)
func extractStr(input map[string]interface{}, key string) string {
	if v, ok := input[key]; ok && v != nil {
		return fmt.Sprintf("%v", v)
	}
	return ""
}

// extractNum safely gets a float64 from a map
func extractNum(input map[string]interface{}, key string) float64 {
	if v, ok := input[key]; ok && v != nil {
		switch n := v.(type) {
		case float64:
			return n
		case int:
			return float64(n)
		case string:
			var f float64
			fmt.Sscanf(n, "%f", &f)
			return f
		}
	}
	return 0
}

// mapToLead converts a JSON map to a Lead model
func mapToLead(input map[string]interface{}) models.Lead {
	lead := models.Lead{
		Name:         extractStr(input, "name"),
		Email:        extractStr(input, "email"),
		Phone:        extractStr(input, "phone"),
		Company:      extractStr(input, "company"),
		CustomerType: extractStr(input, "customer_type"),
		City:         extractStr(input, "city"),
		State:        extractStr(input, "state"),
		FollowUp1:    extractStr(input, "follow_up_1"),
		FollowUp2:    extractStr(input, "follow_up_2"),
		FollowUp3:    extractStr(input, "follow_up_3"),
		Status:       extractStr(input, "status"),
		Value:        extractNum(input, "value"),
		InquiryDate:  parseFlexDate(extractStr(input, "inquiry_date")),
	}
	if lead.Status == "" {
		lead.Status = "New"
	}
	return lead
}

func CreateLead(c *gin.Context) {
	var input map[string]interface{}
	if err := c.ShouldBindJSON(&input); err != nil {
		log.Printf("CreateLead: JSON parse error: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid JSON: " + err.Error()})
		return
	}

	lead := mapToLead(input)

	if result := database.DB.Create(&lead); result.Error != nil {
		log.Printf("CreateLead: DB error: %v", result.Error)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create lead: " + result.Error.Error()})
		return
	}
	c.JSON(http.StatusCreated, lead)
}

// BulkImportLeads accepts an array of lead objects and inserts them in one transaction
func BulkImportLeads(c *gin.Context) {
	var inputs []map[string]interface{}
	if err := c.ShouldBindJSON(&inputs); err != nil {
		log.Printf("BulkImport: JSON parse error: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid JSON: expected array of lead objects"})
		return
	}

	log.Printf("BulkImport: received %d items", len(inputs))

	var leads []models.Lead
	for _, input := range inputs {
		lead := mapToLead(input)
		if lead.Name == "" && lead.Company == "" && lead.Phone == "" {
			continue // skip empty rows
		}
		if lead.Name == "" {
			if lead.Company != "" {
				lead.Name = lead.Company
			} else {
				lead.Name = "Unknown"
			}
		}
		leads = append(leads, lead)
	}

	if len(leads) == 0 {
		c.JSON(http.StatusOK, gin.H{"imported": 0, "message": "No valid leads found"})
		return
	}

	// Batch insert
	var errCount int
	tx := database.DB.Begin()
	for i, lead := range leads {
		if result := tx.Create(&lead); result.Error != nil {
			log.Printf("BulkImport: row %d (%s) error: %v", i+1, lead.Name, result.Error)
			errCount++
		}
	}
	tx.Commit()

	imported := len(leads) - errCount
	log.Printf("BulkImport: imported %d of %d leads (%d errors)", imported, len(leads), errCount)
	c.JSON(http.StatusOK, gin.H{
		"imported": imported,
		"total":    len(leads),
		"message":  fmt.Sprintf("Imported %d of %d leads", imported, len(leads)),
	})
}

func GetLeads(c *gin.Context) {
	var leads []models.Lead
	if result := database.DB.Order("created_at desc").Find(&leads); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch leads"})
		return
	}
	c.JSON(http.StatusOK, leads)
}

func UpdateLead(c *gin.Context) {
	id := c.Param("id")
	var lead models.Lead
	if result := database.DB.First(&lead, id); result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Lead not found"})
		return
	}

	var input map[string]interface{}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	// Only update fields present in input
	updates := make(map[string]interface{})
	for _, key := range []string{"name", "email", "phone", "company", "customer_type",
		"city", "state", "status", "follow_up_1", "follow_up_2", "follow_up_3"} {
		if v, ok := input[key]; ok {
			updates[key] = v
		}
	}
	if v, ok := input["value"]; ok {
		updates["value"] = v
	}
	if v, ok := input["inquiry_date"]; ok {
		if s, ok := v.(string); ok {
			updates["inquiry_date"] = parseFlexDate(s)
		}
	}

	if result := database.DB.Model(&lead).Updates(updates); result.Error != nil {
		log.Printf("UpdateLead: DB error: %v", result.Error)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update lead: " + result.Error.Error()})
		return
	}
	database.DB.First(&lead, id) // reload
	c.JSON(http.StatusOK, lead)
}

func DeleteLead(c *gin.Context) {
	id := c.Param("id")
	if result := database.DB.Delete(&models.Lead{}, id); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete lead"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Lead deleted"})
}

func ClearAllLeads(c *gin.Context) {
	if result := database.DB.Exec("UPDATE quotations SET lead_id = NULL WHERE lead_id IS NOT NULL"); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to unlink leads from quotations"})
		return
	}

	if result := database.DB.Exec("DELETE FROM leads"); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to clear leads"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "All leads cleared"})
}
