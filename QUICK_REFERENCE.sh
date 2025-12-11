#!/bin/bash
# Quick Reference Card for Load-Balanced Reverse Proxy

cat << 'EOF'
╔════════════════════════════════════════════════════════════════════╗
║        LOAD-BALANCED REVERSE PROXY - QUICK REFERENCE              ║
╚════════════════════════════════════════════════════════════════════╝

📋 PROJECT STATUS: ✅ COMPLETE

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 QUICK START
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  1. Build:
     $ go build -o proxy-app .

  2. Automated Test (Recommended):
     $ ./test.sh

  3. Or Manual Test:
     Terminal 1: ./proxy-app -mode backend -id 1
     Terminal 2: ./proxy-app -mode backend -id 2
     Terminal 3: ./proxy-app -mode proxy
     Terminal 4: curl http://localhost:8000/

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 SERVICE ENDPOINTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Backend 1:        http://localhost:8080
  Backend 2:        http://localhost:8081
  HTTP Proxy:       http://localhost:8000
  HTTPS Proxy:      https://localhost:4443 (-k for curl)
  
  Health Check:
  - GET /health

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 LOAD BALANCING VERIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Method 1 - Check Response (Simplest):
  $ curl http://localhost:8000/ | grep "Instance ID"
  Expected: Alternates between "Instance ID: 1" and "Instance ID: 2"

  Method 2 - Check Response Headers:
  $ curl -i http://localhost:8000/ | grep X-Backend-Instance
  Expected: Alternates between "Backend-1" and "Backend-2"

  Method 3 - Check Logs (Best for verification):
  Terminal with proxy shows:
    [Request #1] Routing to: http://localhost:8080
    [Request #2] Routing to: http://localhost:8081
    [Request #3] Routing to: http://localhost:8080
  
  Terminal with backends show requests received:
    [Backend 1] Request: GET / from ...
    [Backend 2] Request: GET / from ...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔐 HTTPS TESTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  1. Start HTTPS proxy:
     $ ./proxy-app -mode proxy -https

  2. Test with curl:
     $ curl -k https://localhost:4443/
     (Use -k to ignore self-signed certificate warning)

  3. Verify load balancing works over HTTPS:
     $ for i in {1..6}; do
         curl -k -s https://localhost:4443/ | grep Instance
       done

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚙️ COMMAND-LINE OPTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Reverse Proxy Mode:
  ./proxy-app -mode proxy [options]
    -backend1 string  First backend URL (default: http://localhost:8080)
    -backend2 string  Second backend URL (default: http://localhost:8081)
    -https           Use HTTPS (port 4443 instead of 8000)

  Backend Mode:
  ./proxy-app -mode backend [options]
    -id int          Backend instance ID: 1 or 2

  Examples:
  $ ./proxy-app -mode proxy
  $ ./proxy-app -mode proxy -https
  $ ./proxy-app -mode backend -id 1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 PROJECT FILES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  main.go              Reverse proxy implementation (184 lines)
  backend.go           Backend service (76 lines)
  go.mod              Go module definition
  test.sh             Automated test suite
  final_test.sh       Quick verification test
  
  certs/
    ├── server.crt    TLS certificate
    ├── server.key    TLS private key
    └── rootCA.crt    Root CA certificate
  
  Documentation:
    ├── README.md           Original documentation
    ├── IMPLEMENTATION.md   Detailed implementation guide
    └── PROJECT_SUMMARY.md  Complete project summary

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🐛 TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  "Address already in use" error:
  $ pkill -f proxy-app && sleep 2

  HTTPS certificate warnings:
  Use -k flag with curl:
  $ curl -k https://localhost:4443/

  Verify backends are running:
  $ curl http://localhost:8080/health
  $ curl http://localhost:8081/health

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ REQUIREMENTS CHECKLIST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ✅ 2 backend instances on different ports (8080, 8081)
  ✅ Round-robin load balancing
  ✅ Verify load balancing in backend logs
  ✅ Verify load balancing in response (Instance ID)
  ✅ HTTP reverse proxy (port 8000)
  ✅ HTTPS reverse proxy (port 4443)
  ✅ Using certificates from certs folder
  ✅ Unique flag in response showing which backend
  ✅ Automated testing script

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 EXPECTED TEST OUTPUT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Running ./test.sh should show:

  HTTP Load Balancing Test (6 requests):
    Request 1: Instance ID: 1
    Request 2: Instance ID: 2
    Request 3: Instance ID: 1
    Request 4: Instance ID: 2
    Request 5: Instance ID: 1
    Request 6: Instance ID: 2

  Backend Distribution:
    Backend 1 received: 3 requests
    Backend 2 received: 3 requests

  HTTPS Load Balancing Test (6 requests):
    [Same alternating pattern over HTTPS]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎓 KEY CONCEPTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Round-Robin:         Each request goes to next backend in sequence
  Load Balancer:       Component distributing requests to backends
  Reverse Proxy:       Server forwarding requests to actual backends
  TLS/HTTPS:           Encrypted communication channel
  Backend:             Actual service handling requests
  Instance ID:         Unique identifier for each backend

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

For more details, see:
  - IMPLEMENTATION.md  (Technical guide)
  - PROJECT_SUMMARY.md (Complete summary)
  - README.md          (Original documentation)

EOF
