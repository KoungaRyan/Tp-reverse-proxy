package main

import (
	"flag"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"path"
	"strings"
	"sync"
	"sync/atomic"

	"html/template"
)

var version string = "0.0.0-local"

var certsDir = "certs"
var serverCertPath = path.Join(certsDir, "server.crt")
var serverKeyPath = path.Join(certsDir, "server.key")

// Load balancer state
type LoadBalancer struct {
	backends      []*url.URL
	currentIndex  atomic.Uint32
	requestCount  atomic.Uint64
	mu            sync.RWMutex
}

var loadBalancer *LoadBalancer

var pingTemplate, _ = template.New("").Parse(`<html>
<title>Reverse Proxy Gateway</title>
<style>
html
{
	background: linear-gradient(0.25turn, rgb(2,0,36) 0%, rgb(59,9,121) 50%, rgb(0,21,66) 100%);
	color: #fafafa;
	margin: 0;
	padding: 10px;
	font-family: Arial, sans-serif;
}
.info-box {
	background: rgba(255,255,255,0.1);
	padding: 15px;
	border-radius: 5px;
	margin: 10px 0;
}
</style>
<h1>Reverse Proxy Gateway v{{.Version}}</h1>
<div class="info-box">
	<p><strong>Status:</strong> Operational</p>
	<p><strong>Load Balancer:</strong> Round-Robin</p>
	<p><strong>Backends:</strong> {{.Backends}}</p>
	<p><strong>Total Requests:</strong> {{.Requests}}</p>
</div>
</html>`)

func init() {
	loadBalancer = &LoadBalancer{}
}

func main() {
	// Command line flags
	var backend1 string
	var backend2 string
	var useHTTPS bool
	var mode string
	var instanceID int

	flag.StringVar(&backend1, "backend1", "http://localhost:8080", "First backend URL")
	flag.StringVar(&backend2, "backend2", "http://localhost:8081", "Second backend URL")
	flag.BoolVar(&useHTTPS, "https", false, "Use HTTPS for reverse proxy")
	flag.StringVar(&mode, "mode", "proxy", "Mode: 'proxy' or 'backend'")
	flag.IntVar(&instanceID, "id", 1, "Backend instance ID (1 or 2)")
	flag.Parse()

	// Check if we should run a backend instead
	if mode == "backend" {
		var port int
		if instanceID == 2 {
			port = 8081
		} else {
			port = 8080
		}
		startBackend(instanceID, port)
		return
	}

	// Initialize load balancer with backends
	parseBackends(backend1, backend2)

	var addr string
	if useHTTPS {
		addr = ":4443"
	} else {
		addr = ":8000"
	}

	server := http.Server{
		Addr:    addr,
		Handler: logReq(mainHandler()),
	}

	if useHTTPS {
		log.Printf("Reverse Proxy (HTTPS) started on %s\n", addr)
		log.Printf("Backends: %s, %s\n", backend1, backend2)
		log.Printf("Using certificates: %s, %s\n", serverCertPath, serverKeyPath)
		if err := server.ListenAndServeTLS(serverCertPath, serverKeyPath); err != nil {
			log.Fatalf("Error: %v\n", err)
		}
	} else {
		log.Printf("Reverse Proxy (HTTP) started on %s\n", addr)
		log.Printf("Backends: %s, %s\n", backend1, backend2)
		if err := server.ListenAndServe(); err != nil {
			log.Fatalf("Error: %v\n", err)
		}
	}
}

func parseBackends(backend1, backend2 string) {
	url1, err := url.Parse(backend1)
	if err != nil {
		log.Fatalf("Invalid backend1 URL: %v", err)
	}
	url2, err := url.Parse(backend2)
	if err != nil {
		log.Fatalf("Invalid backend2 URL: %v", err)
	}
	loadBalancer.backends = []*url.URL{url1, url2}
}

func (lb *LoadBalancer) getNextBackend() *url.URL {
	// Round-robin load balancing
	index := lb.currentIndex.Add(1) - 1
	return lb.backends[index%uint32(len(lb.backends))]
}

// High-order function to generate a log for each incoming request
func logReq(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requestNum := loadBalancer.requestCount.Add(1)
		log.Printf("[Request #%d] from '%s', endpoint: '%s %s'", requestNum, r.RemoteAddr, r.Method, r.RequestURI)
		next.ServeHTTP(w, r)
	})
}

func mainHandler() http.Handler {
	// Health check handler
	pingHandler := http.HandlerFunc(func(res http.ResponseWriter, req *http.Request) {
		backendsStr := strings.Join(func() []string {
			var urls []string
			for _, b := range loadBalancer.backends {
				urls = append(urls, b.String())
			}
			return urls
		}(), ", ")
		
		data := map[string]interface{}{
			"Version":  version,
			"Backends": backendsStr,
			"Requests": loadBalancer.requestCount.Load(),
		}
		pingTemplate.ExecuteTemplate(res, "", data)
	})

	mux := http.NewServeMux()

	// Self hosted health check
	mux.Handle("/ping", pingHandler)
	mux.Handle("/health", pingHandler)

	// Proxy handler for all other paths
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		backend := loadBalancer.getNextBackend()
		log.Printf("[Proxy] Routing to: %s", backend.String())

		proxy := httputil.NewSingleHostReverseProxy(backend)
		proxy.ServeHTTP(w, r)
	})

	return mux
}
