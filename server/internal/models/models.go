package models

import (
	"time"
)

// User role constants
const (
	RoleAdmin    = "admin"
	RoleEmployee = "employee"
)

type User struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Name      string    `json:"name"`
	Email     string    `gorm:"uniqueIndex" json:"email"`
	Password  string    `json:"-"` // Don't expose in JSON
	Role      string    `json:"role"`
	CreatedAt time.Time `json:"created_at"`
}

type QuoteCustomer struct {
	Name    string `json:"name"`
	Email   string `json:"email"`
	Phone   string `json:"phone"`
	Company string `json:"company"`
	Address string `json:"address"`
}

type Lead struct {
	ID           uint       `gorm:"primaryKey" json:"id"`
	Name         string     `json:"name"`
	Email        string     `json:"email"`
	Phone        string     `json:"phone"`
	Company      string     `json:"company"`
	CustomerType string     `json:"customer_type"`
	InquiryDate  *time.Time `json:"inquiry_date"`
	City         string     `json:"city"`
	State        string     `json:"state"`
	FollowUp1    string     `gorm:"column:follow_up_1" json:"follow_up_1"`
	FollowUp2    string     `gorm:"column:follow_up_2" json:"follow_up_2"`
	FollowUp3    string     `gorm:"column:follow_up_3" json:"follow_up_3"`
	Status       string     `json:"status"` // E.g., Contacted, Negotiation, Offer Sent, Deal Closed
	AssignedTo   uint       `json:"assigned_to"`
	Value        float64    `json:"value"`
	CreatedAt    time.Time  `json:"created_at"`
}

type Task struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	AssignedTo  uint      `json:"assigned_to"`
	Status      string    `json:"status"` // E.g., Pending, In Progress, Completed
	DueDate     time.Time `json:"due_date"`
	CreatedAt   time.Time `json:"created_at"`
}

type Deal struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	LeadID    *uint     `json:"lead_id"`
	Amount    float64   `json:"amount"`
	Stage     string    `json:"stage"` // E.g., Lead, Negotiation, Won, Lost
	CreatedAt time.Time `json:"created_at"`
	Lead      *Lead     `gorm:"foreignKey:LeadID" json:"lead,omitempty"`
}

type Quotation struct {
	ID          uint            `gorm:"primaryKey" json:"id"`
	QuoteNumber string          `gorm:"uniqueIndex" json:"quote_number"`
	LeadID      *uint           `json:"lead_id,omitempty"` // Optional link to lead
	Customer    QuoteCustomer   `gorm:"embedded;embeddedPrefix:customer_" json:"customer"`
	Status      string          `json:"status"` // Draft, Pending Approval, Accepted, Sent
	ValidUntil  time.Time       `json:"valid_until"`
	Notes       string          `json:"notes"`
	Subtotal    float64         `json:"subtotal"`
	TaxTotal    float64         `json:"tax_total"`
	TotalAmount float64         `json:"total_amount"`
	CreatedAt   time.Time       `json:"created_at"`
	UpdatedAt   time.Time       `json:"updated_at"`
	Lead        *Lead           `gorm:"foreignKey:LeadID" json:"lead,omitempty"`
	Items       []QuotationItem `gorm:"foreignKey:QuotationID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"items"`
}

type QuotationItem struct {
	ID          uint    `gorm:"primaryKey" json:"id"`
	QuotationID uint    `json:"quotation_id"`
	Product     string  `json:"product"`
	Quantity    int     `json:"quantity"`
	UnitPrice   float64 `json:"unit_price"`
	Discount    float64 `json:"discount"` // Percentage
	GST         float64 `json:"gst"`      // Percentage
	LineTotal   float64 `json:"line_total"`
}

type Dealer struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	Name        string    `json:"name"`
	Company     string    `json:"company"`
	Email       string    `json:"email"`
	Phone       string    `json:"phone"`
	City        string    `json:"city"`
	State       string    `json:"state"`
	Address     string    `json:"address"`
	GSTNumber   string    `json:"gst_number"`
	DealerCode  string    `gorm:"uniqueIndex" json:"dealer_code"`
	Status      string    `json:"status"` // Active, Inactive, Suspended
	CreditLimit float64   `json:"credit_limit"`
	Notes       string    `json:"notes"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}
