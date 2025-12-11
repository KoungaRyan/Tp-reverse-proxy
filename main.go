package main

import (
	"log"
	"net/http"

	"html/template"
	"path"
)

var version string = "0.0.0-local"

var certsDir = "certs"
var serverCertPath = path.Join(certsDir, "server.crt")
var serverKeyPath = path.Join(certsDir, "server.key")

var pingTemplate, _ = template.New("").Parse(`<html>
<title>Gateway</title>
<style>
html
{
	background: linear-gradient(0.25turn, rgb(2,0,36) 0%, rgb(59,9,121) 50%, rgb(0,21,66) 100%);
	color: #fafafa;
	margin: 0;
	padding: 10px;
}
</style>
<h1>ping success v{{.}}</h1>
</html>`)

func main() {

	server := http.Server{
		Addr:    ":4443",
		Handler: logReq(mainHandler()),
	}

	log.Printf("Server started with %v, %v, listening on %v\n", serverCertPath, serverKeyPath, server.Addr)
	server.ListenAndServe()
}

// High-order function to generate a log for each incoming request
func logReq(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Printf("New request from '%s', endpoint: '%s %s'", r.RemoteAddr, r.Method, r.RequestURI)
		next.ServeHTTP(w, r)
	})
}

func mainHandler() http.Handler {

	// For testing the proxy health. A better approach is with ExecuteTemplate form the html/template package
	pingHandler := http.HandlerFunc(func(res http.ResponseWriter, req *http.Request) {
		pingTemplate.ExecuteTemplate(res, "", version)
	})

	mux := http.NewServeMux()

	// Self hosted
	mux.Handle("/ping", pingHandler)

	return mux
}
