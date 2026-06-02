package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
)

type HealthResponse struct {
	Status  string `json:"status"`
	Service string `json:"service"`
}

type Notification struct {
	ID      int    `json:"id"`
	Type    string `json:"type"`
	Message string `json:"message"`
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

func HealthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	resp := HealthResponse{
		Status:  "UP",
		Service: "notification-service",
	}
	_ = json.NewEncoder(w).Encode(resp)
}

func NotificationsHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	notifications := []Notification{
		{ID: 1001, Type: "EMAIL", Message: "Welcome onboard!"},
		{ID: 1002, Type: "SMS", Message: "Your OTP is 482910"},
	}
	_ = json.NewEncoder(w).Encode(notifications)
}

func main() {
	host := getEnv("HOST", "127.0.0.1")
	port := getEnv("PORT", "5000")
	address := fmt.Sprintf("%s:%s", host, port)

	http.HandleFunc("/health", HealthHandler)
	http.HandleFunc("/api/notifications", NotificationsHandler)

	fmt.Printf("Notification Service starting on http://%s\n", address)
	if err := http.ListenAndServe(address, nil); err != nil {
		fmt.Printf("Error starting server: %s\n", err)
	}
}
