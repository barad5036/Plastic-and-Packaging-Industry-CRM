package dashboard

import (
	"net/http"

	"crm-server/internal/models"
	"crm-server/pkg/database"

	"github.com/gin-gonic/gin"
)

type DashboardSummary struct {
	TotalCustomers int64   `json:"total_customers"`
	TotalTasks     int64   `json:"total_tasks"`
	PendingTasks   int64   `json:"pending_tasks"`
	TotalRevenue   float64 `json:"total_revenue"`
}

func GetSummary(c *gin.Context) {
	var summary DashboardSummary

	// Count total tasks and pending tasks
	database.DB.Model(&models.Task{}).Count(&summary.TotalTasks)
	database.DB.Model(&models.Task{}).Where("status != ?", "Completed").Count(&summary.PendingTasks)

	// Calculate total revenue from closed/won deals + closed leads
	type Result struct {
		Total float64
	}
	var dealRes Result
	database.DB.Model(&models.Deal{}).Select("COALESCE(sum(amount), 0) as total").Where("stage = ?", "Deal Closed").Scan(&dealRes)

	var leadRes Result
	database.DB.Model(&models.Lead{}).Select("COALESCE(sum(value), 0) as total").Where("status = ?", "Order Confirmed").Scan(&leadRes)

	summary.TotalRevenue = dealRes.Total + leadRes.Total

	c.JSON(http.StatusOK, summary)
}
