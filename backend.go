package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

// Backend instance info
type BackendInstance struct {
	ID   int
	Port int
}

func startBackend(instanceID int, port int) {
	mux := http.NewServeMux()

	// Handler that returns a response with the instance ID
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		log.Printf("[Backend %d] Request: %s %s from %s", instanceID, r.Method, r.RequestURI, r.RemoteAddr)
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		w.Header().Set("X-Backend-Instance", fmt.Sprintf("Backend-%d", instanceID))
		
		response := fmt.Sprintf(`<html>
<title>Backend Service</title>
<style>
html {
	background: linear-gradient(0.25turn, rgb(2,0,36) 0%%, rgb(59,9,121) 50%%, rgb(0,21,66) 100%%);
	color: #fafafa;
	margin: 0;
	padding: 20px;
	font-family: Arial, sans-serif;
}
.badge {
	background-color: #00ff00;
	color: #000;
	padding: 10px 20px;
	border-radius: 5px;
	display: inline-block;
	font-weight: bold;
	margin-bottom: 20px;
}
</style>
<h1>Backend Service</h1>
<div class="badge">Instance ID: %d | Port: %d</div>
<p>Request Path: %s</p>
<p>Request Time: %s</p>
</html>`, instanceID, port, r.RequestURI, getCurrentTime())
		
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(response))
	})

	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		log.Printf("[Backend %d] Health check", instanceID)
		w.Header().Set("X-Backend-Instance", fmt.Sprintf("Backend-%d", instanceID))
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(fmt.Sprintf(`{"status":"healthy","instance":%d}`, instanceID)))
	})

	server := &http.Server{
		Addr:    fmt.Sprintf(":%d", port),
		Handler: mux,
	}

	log.Printf("Backend %d starting on port %d\n", instanceID, port)
	if err := server.ListenAndServe(); err != nil {
		log.Printf("Backend %d error: %v\n", instanceID, err)
		os.Exit(1)
	}
}

func getCurrentTime() string {
	return fmt.Sprintf("%v", os.Getenv("TEST_TIME"))
}
