package database

import (
	"fmt"
	"log"
	"os"

	"crm-server/internal/models"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var DB *gorm.DB

func IsConnected() bool {
	return DB != nil
}

func ConnectDB() {
	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		databaseURL = os.Getenv("POSTGRES_URL")
	}

	var dsn string
	if databaseURL != "" {
		dsn = databaseURL
	} else {
		host := os.Getenv("DB_HOST")
		user := os.Getenv("DB_USER")
		password := os.Getenv("DB_PASSWORD")
		dbname := os.Getenv("DB_NAME")
		port := os.Getenv("DB_PORT")
		sslmode := os.Getenv("DB_SSLMODE")
		if sslmode == "" {
			sslmode = "disable"
		}

		if host == "" && user == "" {
			log.Println("WARNING: No database config found. API endpoints requiring DB will fail.")
			return
		}

		dsn = fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=%s TimeZone=UTC",
			host, user, password, dbname, port, sslmode)
	}

	var err error
	DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Printf("WARNING: Failed to connect to database: %v\n", err)
		return
	}

	log.Println("Connected to Database!")

	// Auto Migrate
	err = DB.AutoMigrate(&models.User{}, &models.Lead{}, &models.Task{}, &models.Deal{}, &models.Quotation{}, &models.QuotationItem{}, &models.Dealer{})
	if err != nil {
		log.Printf("WARNING: Failed to migrate database: %v\n", err)
	} else {
		log.Println("Database Migrated!")
	}
}
