# Load-Balanced Reverse Proxy with HTTPS

A fully functional reverse proxy implementing round-robin load balancing with HTTP and HTTPS support.

## Summary

This project provides:
- ✅ **Round-robin load balancing** between 2 backend instances
- ✅ **HTTP reverse proxy** on port 8000
- ✅ **HTTPS reverse proxy** on port 4443 with TLS certificates
- ✅ **Load balancing verification** through instance ID identification and request logs
- ✅ **Automated testing** with detailed logging

## Quick Start

```bash
# Build the application
go build -o proxy-app .

# Run automated tests (HTTP + HTTPS load balancing)
./test.sh
```

## Architecture

```
Clients (HTTP/HTTPS)
    ↓
Reverse Proxy (HTTP:8000 / HTTPS:4443)
    ├→ Backend 1 (HTTP:8080)
    └→ Backend 2 (HTTP:8081)
```

## Features Implemented

### 1. Load Balancing ✅

**Round-robin algorithm** distributes requests sequentially:
- Request 1 → Backend 1 (port 8080)
- Request 2 → Backend 2 (port 8081)
- Request 3 → Backend 1 (port 8080)
- And so on...

**Verified by:**
- Response HTML shows `Instance ID: 1` or `Instance ID: 2`
- Response header: `X-Backend-Instance: Backend-N`
- Proxy logs show routing decisions
- Backend logs confirm received requests

### 2. Two Backend Instances ✅

Each backend:
- Runs on different port (8080, 8081)
- Identifies itself with unique instance ID
- Logs all incoming requests
- Responds with instance information in HTML response
- Provides `/health` endpoint for monitoring

### 3. HTTP Reverse Proxy ✅

- Listens on port 8000
- Uses `httputil.NewSingleHostReverseProxy`
- Implements round-robin load balancing
- Logs all incoming requests with sequence numbers

### 4. HTTPS Reverse Proxy ✅

- Listens on port 4443
- Uses certificates from `certs/` folder:
  - `server.crt` - Server certificate
  - `server.key` - Server private key
- Same load balancing as HTTP proxy
- Client-to-proxy: HTTPS encrypted
- Proxy-to-backend: HTTP (unencrypted)

## File Structure

```
Tp-reverse-proxy/
├── main.go              # Reverse proxy + mode handling
├── backend.go           # Backend service implementation
├── go.mod              # Go module definition
├── test.sh             # Automated test script
├── certs/
│   ├── server.crt
│   ├── server.key
│   └── rootCA.crt
└── README.md (original)
```

## Running the Application

### Automated Testing (Recommended)

```bash
./test.sh
```

This script:
1. Builds the application
2. Starts Backend 1 (port 8080)
3. Starts Backend 2 (port 8081)
4. Starts HTTP reverse proxy (port 8000)
5. Sends 6 test requests and verifies load balancing
6. Starts HTTPS reverse proxy (port 4443)
7. Sends 6 HTTPS test requests
8. Displays all logs showing load balancing in action

### Manual Testing

**Terminal 1 - Start Backend 1:**
```bash
./proxy-app -mode backend -id 1
```

**Terminal 2 - Start Backend 2:**
```bash
./proxy-app -mode backend -id 2
```

**Terminal 3 - Start HTTP Proxy (without HTTPS):**
```bash
./proxy-app -mode proxy
```

**OR Terminal 3 - Start HTTPS Proxy:**
```bash
./proxy-app -mode proxy -https
```

**Terminal 4 - Test the proxy:**
```bash
# HTTP requests
curl http://localhost:8000/
curl http://localhost:8000/health

# HTTPS requests (ignore cert warning)
curl -k https://localhost:4443/
curl -k https://localhost:4443/health
```

## Load Balancing Verification

### Method 1: HTML Response (Instance ID)

```bash
# Make repeated requests and check instance ID
for i in {1..6}; do
  curl -s http://localhost:8000/ | grep "Instance ID"
  sleep 0.5
done
```

Expected output (alternating):
```
Instance ID: 1 | Port: 8080
Instance ID: 2 | Port: 8081
Instance ID: 1 | Port: 8080
Instance ID: 2 | Port: 8081
Instance ID: 1 | Port: 8080
Instance ID: 2 | Port: 8081
```

### Method 2: Response Headers

```bash
curl -i http://localhost:8000/
```

Look for `X-Backend-Instance: Backend-1` or `Backend-2`

### Method 3: Server Logs

Check the proxy logs showing alternating routing:
```
[Request #1] Routing to: http://localhost:8080
[Request #2] Routing to: http://localhost:8081
[Request #3] Routing to: http://localhost:8080
[Request #4] Routing to: http://localhost:8081
```

Check backend logs confirming request distribution:
```
// Backend 1 log
[Backend 1] Request: GET / from 127.0.0.1:xxxxx
[Backend 1] Request: GET / from 127.0.0.1:xxxxx

// Backend 2 log
[Backend 2] Request: GET / from 127.0.0.1:yyyyy
[Backend 2] Request: GET / from 127.0.0.1:yyyyy
```

## Command-Line Usage

### Reverse Proxy (Load Balancer)

```bash
./proxy-app -mode proxy [options]
```

Options:
- `-backend1 string` - First backend URL (default: http://localhost:8080)
- `-backend2 string` - Second backend URL (default: http://localhost:8081)
- `-https` - Enable HTTPS (uses port 4443 instead of 8000)

Examples:
```bash
./proxy-app -mode proxy                           # HTTP proxy on 8000
./proxy-app -mode proxy -https                    # HTTPS proxy on 4443
./proxy-app -mode proxy -backend1 http://b1:80 -backend2 http://b2:80  # Custom backends
```

### Backend Service

```bash
./proxy-app -mode backend -id 1  # Backend 1 on port 8080
./proxy-app -mode backend -id 2  # Backend 2 on port 8081
```

## Test Script Output

The test script (`test.sh`) produces detailed logs showing:

**HTTP Test Results:**
```
Request 1: Instance ID: 1  ✓ Backend 1 received
Request 2: Instance ID: 2  ✓ Backend 2 received
Request 3: Instance ID: 1  ✓ Backend 1 received
Request 4: Instance ID: 2  ✓ Backend 2 received
Request 5: Instance ID: 1  ✓ Backend 1 received
Request 6: Instance ID: 2  ✓ Backend 2 received
```

**Proxy Routing Logs:**
```
[Request #1] Routing to: http://localhost:8080
[Request #2] Routing to: http://localhost:8081
[Request #3] Routing to: http://localhost:8080
...
```

**Backend Request Logs:**
```
Backend 1: Received 3 requests (odd-numbered)
Backend 2: Received 3 requests (even-numbered)
```

**HTTPS Test Results:**
```
Request 1 (HTTPS): Instance ID: 1  ✓
Request 2 (HTTPS): Instance ID: 2  ✓
...
```

## Implementation Highlights

### Load Balancing Algorithm

```go
type LoadBalancer struct {
    backends     []*url.URL
    currentIndex atomic.Uint32
}

func (lb *LoadBalancer) getNextBackend() *url.URL {
    index := lb.currentIndex.Add(1) - 1
    return lb.backends[index%uint32(len(lb.backends))]
}
```

- **Thread-safe**: Uses `atomic.Uint32` for concurrent requests
- **Simple & effective**: Modulo operation ensures round-robin
- **No state**: Each request independently routes to next backend

### Reverse Proxy Setup

```go
proxy := httputil.NewSingleHostReverseProxy(backend)
proxy.ServeHTTP(w, r)
```

- Uses Go's standard library `httputil` package
- Single-host reverse proxy pattern
- Transparent request/response forwarding

### HTTPS Configuration

```go
server.ListenAndServeTLS(serverCertPath, serverKeyPath)
```

- TLS termination at proxy
- HTTP communication to backends
- Clients see HTTPS endpoint

## Troubleshooting

### "Address already in use" error
```bash
pkill -f proxy-app
sleep 2
```

### HTTPS certificate warnings
Use curl with `-k` flag to ignore self-signed certificate:
```bash
curl -k https://localhost:4443/
```

### Requests only reaching one backend
Check that both backends are running and accessible:
```bash
curl http://localhost:8080/health
curl http://localhost:8081/health
```

## Requirements

- Go 1.21 or later
- No external dependencies (uses Go standard library)

## Testing Scenarios

### Scenario 1: Verify Load Balancing
```bash
./test.sh
# Automatic verification with detailed logs
```

### Scenario 2: Manual Load Test
```bash
# Terminal 1-2
./proxy-app -mode backend -id 1 &
./proxy-app -mode backend -id 2 &

# Terminal 3
./proxy-app -mode proxy

# Terminal 4
for i in {1..100}; do curl -s http://localhost:8000/ | grep Instance; done | sort | uniq -c
# Should show ~50 requests to each backend
```

### Scenario 3: Backend Failure Recovery
```bash
# Start all services
./proxy-app -mode backend -id 1 &
./proxy-app -mode backend -id 2 &
./proxy-app -mode proxy &

# Send requests
for i in {1..10}; do curl -s http://localhost:8000/ | grep Instance; sleep 0.2; done

# Kill backend 1 (Ctrl+C)
# Continue testing - notice requests alternate between backends with error for dead one
```

### Scenario 4: HTTPS Encryption
```bash
./proxy-app -mode backend -id 1 &
./proxy-app -mode backend -id 2 &
./proxy-app -mode proxy -https

# Capture traffic with tcpdump to verify encryption
curl -k https://localhost:4443/
```

## Summary of Requirements

| Requirement | Status | Implementation |
|-------------|--------|-----------------|
| 2 backend instances on different ports | ✅ | Port 8080, 8081 with unique IDs |
| Reverse proxy traffic distribution | ✅ | Round-robin to both backends |
| Load balancing verification (logs) | ✅ | Proxy logs show routing, backend logs show requests |
| Load balancing verification (response) | ✅ | HTML shows Instance ID, header shows Backend-N |
| HTTP reverse proxy | ✅ | Port 8000 with working reverse proxy |
| HTTPS reverse proxy | ✅ | Port 4443 with TLS certificates |
| Certificate usage | ✅ | Using certs/server.crt and certs/server.key |
| Automated testing | ✅ | test.sh verifies all functionality |

## Conclusion

This implementation provides a complete, working reverse proxy with:
- ✅ Verified round-robin load balancing
- ✅ HTTP and HTTPS support
- ✅ Comprehensive logging for verification
- ✅ Easy-to-use test script
- ✅ Clean, maintainable code using Go standard library
