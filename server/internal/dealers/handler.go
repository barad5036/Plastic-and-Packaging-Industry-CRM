package dealers

import (
	"fmt"
	"net/http"
	"time"

	"crm-server/internal/models"
	"crm-server/pkg/database"

	"github.com/gin-gonic/gin"
)

func GetDealers(c *gin.Context) {
	var dealers []models.Dealer
	query := database.DB.Order("created_at desc")

	if search := c.Query("search"); search != "" {
		like := "%" + search + "%"
		query = query.Where("name ILIKE ? OR company ILIKE ? OR dealer_code ILIKE ? OR city ILIKE ? OR phone ILIKE ?", like, like, like, like, like)
	}
	if status := c.Query("status"); status != "" && status != "All" {
		query = query.Where("status = ?", status)
	}

	if err := query.Find(&dealers).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch dealers"})
		return
	}
	c.JSON(http.StatusOK, dealers)
}

func GetDealer(c *gin.Context) {
	id := c.Param("id")
	var dealer models.Dealer
	if err := database.DB.First(&dealer, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Dealer not found"})
		return
	}
	c.JSON(http.StatusOK, dealer)
}

func CreateDealer(c *gin.Context) {
	var dealer models.Dealer
	if err := c.ShouldBindJSON(&dealer); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	if dealer.Name == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dealer name is required"})
		return
	}

	if dealer.DealerCode == "" {
		dealer.DealerCode = fmt.Sprintf("DL-%d-%04d", time.Now().Year(), time.Now().Unix()%10000)
	}
	if dealer.Status == "" {
		dealer.Status = "Active"
	}

	if err := database.DB.Create(&dealer).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create dealer"})
		return
	}
	c.JSON(http.StatusCreated, dealer)
}

func UpdateDealer(c *gin.Context) {
	id := c.Param("id")
	var dealer models.Dealer
	if err := database.DB.First(&dealer, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Dealer not found"})
		return
	}

	if err := c.ShouldBindJSON(&dealer); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	database.DB.Save(&dealer)
	c.JSON(http.StatusOK, dealer)
}

func DeleteDealer(c *gin.Context) {
	id := c.Param("id")
	if err := database.DB.Delete(&models.Dealer{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete dealer"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Dealer deleted"})
}
