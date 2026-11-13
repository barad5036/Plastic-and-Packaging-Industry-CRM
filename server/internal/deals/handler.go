package deals

import (
	"net/http"

	"crm-server/internal/models"
	"crm-server/pkg/database"

	"github.com/gin-gonic/gin"
)

func CreateDeal(c *gin.Context) {
	var deal models.Deal
	if err := c.ShouldBindJSON(&deal); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	if result := database.DB.Create(&deal); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create deal"})
		return
	}
	c.JSON(http.StatusCreated, deal)
}

func GetDeals(c *gin.Context) {
	var deals []models.Deal
	if result := database.DB.Find(&deals); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch deals"})
		return
	}
	c.JSON(http.StatusOK, deals)
}

func UpdateDeal(c *gin.Context) {
	id := c.Param("id")
	var deal models.Deal
	if result := database.DB.First(&deal, id); result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Deal not found"})
		return
	}

	if err := c.ShouldBindJSON(&deal); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	database.DB.Save(&deal)
	c.JSON(http.StatusOK, deal)
}

func DeleteDeal(c *gin.Context) {
	id := c.Param("id")
	if result := database.DB.Delete(&models.Deal{}, id); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete deal"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Deal deleted"})
}
