package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

const baseURL = "http://localhost:8080"

func main() {
	fmt.Println("=== CRM Data Seeder ===")
	fmt.Println()

	// 1. Register admin
	register("Admin User", "admin@bizlink.com", "admin123", "admin")

	// 2. Login
	token := login("admin@bizlink.com", "admin123")
	if token == "" {
		fmt.Println("ERROR: Login failed — cannot seed data")
		return
	}
	fmt.Printf("Logged in, token: %s...\n\n", token[:30])

	// 3. Seed customers
	customers := []map[string]string{
		{"name": "Alice Smith", "company": "Tech Corp", "email": "alice@techcorp.com", "phone": "+1 555-0100", "address": "123 Main St, San Francisco"},
		{"name": "Bob Johnson", "company": "Acme Inc", "email": "bob@acme.com", "phone": "+1 555-0200", "address": "456 Oak Ave, New York"},
		{"name": "Carol Davis", "company": "DataFlow", "email": "carol@dataflow.com", "phone": "+1 555-0300", "address": "789 Pine Rd, Austin"},
		{"name": "David Wilson", "company": "CloudNet", "email": "david@cloudnet.com", "phone": "+1 555-0400", "address": "321 Elm St, Seattle"},
		{"name": "Eva Martinez", "company": "DigitalPeak", "email": "eva@digitalpeak.com", "phone": "+1 555-0500", "address": "654 Maple Dr, Denver"},
	}
	for _, c := range customers {
		post(token, "/api/customers", c)
		fmt.Printf("  Created customer: %s\n", c["name"])
	}
	fmt.Println()

	// 4. Seed leads in different pipeline stages
	leads := []map[string]interface{}{
		{"name": "James Brown", "company": "Prime Estate", "email": "james@prime.com", "phone": "+1 555-1000", "status": "Contacted", "value": 20000.0},
		{"name": "Sarah Lee", "company": "CloudTech", "email": "sarah@cloudtech.com", "phone": "+1 555-1100", "status": "Contacted", "value": 35000.0},
		{"name": "Mike Chen", "company": "DataSoft", "email": "mike@datasoft.com", "phone": "+1 555-1200", "status": "Negotiation", "value": 80000.0},
		{"name": "Anna Park", "company": "WebApps", "email": "anna@webapps.com", "phone": "+1 555-1300", "status": "Negotiation", "value": 55000.0},
		{"name": "Tom Wright", "company": "AI Labs", "email": "tom@ailabs.com", "phone": "+1 555-1400", "status": "Offer Sent", "value": 120000.0},
		{"name": "Laura Gold", "company": "FinServe", "email": "laura@finserve.com", "phone": "+1 555-1500", "status": "Deal Closed", "value": 150000.0},
		{"name": "Chris Young", "company": "MediaPro", "email": "chris@mediapro.com", "phone": "+1 555-1600", "status": "Deal Closed", "value": 95000.0},
	}
	for _, l := range leads {
		post(token, "/api/leads", l)
		fmt.Printf("  Created lead: %s (%s)\n", l["name"], l["status"])
	}
	fmt.Println()

	// 5. Seed tasks
	tasks := []map[string]interface{}{
		{"title": "Review Q3 Marketing Strategy", "description": "Analyze campaign performance and plan Q4", "status": "Pending", "due_date": "2026-03-15T00:00:00Z"},
		{"title": "Update CRM Customer Data", "description": "Clean up duplicate entries and verify contacts", "status": "In Progress", "due_date": "2026-03-12T00:00:00Z"},
		{"title": "Send Partnership Proposals", "description": "Draft and send proposals to 3 new partners", "status": "Completed", "due_date": "2026-03-10T00:00:00Z"},
		{"title": "Prepare Sales Report", "description": "Generate monthly sales metrics report", "status": "Pending", "due_date": "2026-03-20T00:00:00Z"},
		{"title": "Client Onboarding Call", "description": "Welcome call with DataFlow team", "status": "In Progress", "due_date": "2026-03-08T00:00:00Z"},
		{"title": "Demo Preparation", "description": "Prepare product demo for AI Labs meeting", "status": "Pending", "due_date": "2026-03-18T00:00:00Z"},
	}
	for _, t := range tasks {
		post(token, "/api/tasks", t)
		fmt.Printf("  Created task: %s (%s)\n", t["title"], t["status"])
	}

	fmt.Println()
	fmt.Println("=== Seeding Complete! ===")

	// Verify
	fmt.Println()
	fmt.Println("=== Verification ===")
	getCount(token, "/api/customers", "Customers")
	getCount(token, "/api/leads", "Leads")
	getCount(token, "/api/tasks", "Tasks")
	getSummary(token, "/api/dashboard/summary")
}

func register(name, email, password, role string) {
	data := map[string]string{"name": name, "email": email, "password": password, "role": role}
	body, _ := json.Marshal(data)
	resp, err := http.Post(baseURL+"/auth/register", "application/json", bytes.NewReader(body))
	if err != nil {
		fmt.Printf("Register request failed: %v\n", err)
		return
	}
	defer resp.Body.Close()
	respBody, _ := io.ReadAll(resp.Body)
	fmt.Printf("Register: %s\n", string(respBody))
}

func login(email, password string) string {
	data := map[string]string{"email": email, "password": password}
	body, _ := json.Marshal(data)
	resp, err := http.Post(baseURL+"/auth/login", "application/json", bytes.NewReader(body))
	if err != nil {
		fmt.Printf("Login request failed: %v\n", err)
		return ""
	}
	defer resp.Body.Close()
	var result map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&result)
	if t, ok := result["token"].(string); ok {
		return t
	}
	return ""
}

func post(token, path string, data interface{}) {
	body, _ := json.Marshal(data)
	req, _ := http.NewRequest("POST", baseURL+path, bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)
	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		fmt.Printf("  ERROR: %v\n", err)
		return
	}
	defer resp.Body.Close()
}

func getCount(token, path, label string) {
	req, _ := http.NewRequest("GET", baseURL+path, nil)
	req.Header.Set("Authorization", "Bearer "+token)
	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		fmt.Printf("  %s: ERROR %v\n", label, err)
		return
	}
	defer resp.Body.Close()
	var items []interface{}
	json.NewDecoder(resp.Body).Decode(&items)
	fmt.Printf("  %s: %d records\n", label, len(items))
}

func getSummary(token, path string) {
	req, _ := http.NewRequest("GET", baseURL+path, nil)
	req.Header.Set("Authorization", "Bearer "+token)
	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		fmt.Printf("  Dashboard: ERROR %v\n", err)
		return
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	fmt.Printf("  Dashboard Summary: %s\n", string(body))
}
