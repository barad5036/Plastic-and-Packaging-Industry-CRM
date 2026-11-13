package quotes

import (
	"fmt"
	"math"
	"net/http"
	"strings"
	"time"

	"crm-server/internal/models"
	"crm-server/pkg/database"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// ---------- request / helper types ----------

type itemPayload struct {
	Product   string  `json:"product"`
	Quantity  int     `json:"quantity"`
	UnitPrice float64 `json:"unit_price"`
	Discount  float64 `json:"discount"`
	GST       float64 `json:"gst"`
}

type customerPayload struct {
	ID      uint   `json:"id"`
	Name    string `json:"name"`
	Email   string `json:"email"`
	Phone   string `json:"phone"`
	Company string `json:"company"`
	Address string `json:"address"`
}

type quotationRequest struct {
	QuoteNumber string          `json:"quote_number"`
	CustomerID  uint            `json:"customer_id"`
	LeadID      *uint           `json:"lead_id"`
	Status      string          `json:"status"`
	ValidUntil  string          `json:"valid_until"`
	Notes       string          `json:"notes"`
	Customer    customerPayload `json:"customer"`
	Items       []itemPayload   `json:"items"`
}

// ---------- helpers ----------

func round2(v float64) float64 {
	return math.Round(v*100) / 100
}

func buildItems(payloads []itemPayload) ([]models.QuotationItem, float64, float64) {
	var subtotal, taxTotal float64
	items := make([]models.QuotationItem, 0, len(payloads))
	for _, p := range payloads {
		base := float64(p.Quantity) * p.UnitPrice * (1 - p.Discount/100)
		tax := base * p.GST / 100
		lineTotal := round2(base + tax)
		subtotal += round2(base)
		taxTotal += round2(tax)
		items = append(items, models.QuotationItem{
			Product:   p.Product,
			Quantity:  p.Quantity,
			UnitPrice: p.UnitPrice,
			Discount:  p.Discount,
			GST:       p.GST,
			LineTotal: lineTotal,
		})
	}
	return items, round2(subtotal), round2(taxTotal)
}

func preloadQuotation(db *gorm.DB) *gorm.DB {
	return db.Preload("Items").Preload("Customer").Preload("Lead")
}

// ---------- handlers ----------

func GetQuotations(c *gin.Context) {
	var quotes []models.Quotation
	query := preloadQuotation(database.DB).Order("created_at desc")

	// Status filter
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}

	// Search across multiple fields
	if search := strings.TrimSpace(c.Query("search")); search != "" {
		like := "%" + strings.ToLower(search) + "%"
		query = query.Where(
			database.DB.Where("LOWER(quote_number) LIKE ?", like).
				Or("LOWER(notes) LIKE ?", like).
				Or("customer_id IN (SELECT id FROM customers WHERE LOWER(name) LIKE ? OR LOWER(company) LIKE ?)", like, like).
				Or("lead_id IN (SELECT id FROM leads WHERE LOWER(name) LIKE ? OR LOWER(company) LIKE ?)", like, like).
				Or("id IN (SELECT quotation_id FROM quotation_items WHERE LOWER(product) LIKE ?)", like),
		)
	}

	if err := query.Find(&quotes).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to query quotations"})
		return
	}
	c.JSON(http.StatusOK, quotes)
}

func GetQuotation(c *gin.Context) {
	id := c.Param("id")
	var quote models.Quotation
	if err := preloadQuotation(database.DB).First(&quote, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Quotation not found"})
		return
	}
	c.JSON(http.StatusOK, quote)
}

func CreateQuotation(c *gin.Context) {
	var req quotationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if len(req.Items) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "At least one line item is required"})
		return
	}

	items, subtotal, taxTotal := buildItems(req.Items)

	var validUntil time.Time
	if req.ValidUntil != "" {
		parsed, err := time.Parse(time.RFC3339, req.ValidUntil)
		if err != nil {
			parsed, err = time.Parse("2006-01-02", req.ValidUntil)
			if err != nil {
				validUntil = time.Now().AddDate(0, 1, 0)
			} else {
				validUntil = parsed
			}
		} else {
			validUntil = parsed
		}
	} else {
		validUntil = time.Now().AddDate(0, 1, 0)
	}

	status := strings.TrimSpace(req.Status)
	if status == "" {
		status = "Draft"
	}

	quoteNumber := strings.TrimSpace(req.QuoteNumber)
	if quoteNumber == "" {
		quoteNumber = fmt.Sprintf("QT-%d-%04d", time.Now().Year(), time.Now().Unix()%10000)
	}

	var savedQuote models.Quotation
	err := database.DB.Transaction(func(tx *gorm.DB) error {
		savedQuote = models.Quotation{
			QuoteNumber: quoteNumber,
			LeadID:      req.LeadID,
			Customer: models.QuoteCustomer{
				Name:    req.Customer.Name,
				Email:   req.Customer.Email,
				Phone:   req.Customer.Phone,
				Company: req.Customer.Company,
				Address: req.Customer.Address,
			},
			Status:      status,
			ValidUntil:  validUntil,
			Notes:       strings.TrimSpace(req.Notes),
			Subtotal:    subtotal,
			TaxTotal:    taxTotal,
			TotalAmount: round2(subtotal + taxTotal),
			Items:       items,
		}
		return tx.Create(&savedQuote).Error
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create quotation: " + err.Error()})
		return
	}

	// Reload with relationships
	preloadQuotation(database.DB).First(&savedQuote, savedQuote.ID)
	c.JSON(http.StatusCreated, savedQuote)
}

func UpdateQuotation(c *gin.Context) {
	id := c.Param("id")
	var existing models.Quotation
	if err := database.DB.Preload("Items").First(&existing, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Quotation not found"})
		return
	}

	var req quotationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := database.DB.Transaction(func(tx *gorm.DB) error {
		// Update customer if provided
		if req.Customer.Name != "" {
			existing.Customer = models.QuoteCustomer{
				Name:    req.Customer.Name,
				Email:   req.Customer.Email,
				Phone:   req.Customer.Phone,
				Company: req.Customer.Company,
				Address: req.Customer.Address,
			}
		}

		if req.LeadID != nil {
			existing.LeadID = req.LeadID
		}
		if s := strings.TrimSpace(req.Status); s != "" {
			existing.Status = s
		}
		if req.ValidUntil != "" {
			if parsed, err := time.Parse(time.RFC3339, req.ValidUntil); err == nil {
				existing.ValidUntil = parsed
			} else if parsed, err := time.Parse("2006-01-02", req.ValidUntil); err == nil {
				existing.ValidUntil = parsed
			}
		}
		if req.Notes != "" {
			existing.Notes = strings.TrimSpace(req.Notes)
		}

		// Replace items if provided
		if len(req.Items) > 0 {
			// Delete old items
			if err := tx.Where("quotation_id = ?", existing.ID).Delete(&models.QuotationItem{}).Error; err != nil {
				return err
			}
			items, subtotal, taxTotal := buildItems(req.Items)
			for i := range items {
				items[i].QuotationID = existing.ID
			}
			existing.Items = items
			existing.Subtotal = subtotal
			existing.TaxTotal = taxTotal
			existing.TotalAmount = round2(subtotal + taxTotal)

			if err := tx.Create(&items).Error; err != nil {
				return err
			}
		}

		return tx.Save(&existing).Error
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update quotation"})
		return
	}

	// Reload with relationships
	preloadQuotation(database.DB).First(&existing, existing.ID)
	c.JSON(http.StatusOK, existing)
}

func DeleteQuotation(c *gin.Context) {
	id := c.Param("id")

	err := database.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Where("quotation_id = ?", id).Delete(&models.QuotationItem{}).Error; err != nil {
			return err
		}
		return tx.Delete(&models.Quotation{}, id).Error
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete quotation"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Quotation deleted"})
}
