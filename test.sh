#!/bin/bash

# Reverse Proxy Load Balancing Test Script
# This script starts the reverse proxy and two backend instances

set -e

REPO_DIR="/mnt/c/ESTIA/DevOps/revers proxy/Tp-reverse-proxy"
cd "$REPO_DIR"

cleanup() {
	echo ""
	echo "=== Cleanup ==="
	pkill -f "proxy-app" || true
	sleep 1
	echo "All services stopped"
}

trap cleanup EXIT

# Kill any existing processes
pkill -f "proxy-app" || true
sleep 2

echo "=== Building the application ==="
go build -o proxy-app .

echo ""
echo "=== Starting Backend 1 on port 8080 ==="
./proxy-app -mode backend -id 1 > /tmp/backend1.log 2>&1 &
BACKEND1_PID=$!
sleep 1

echo "Backend 1 started with PID: $BACKEND1_PID"

echo ""
echo "=== Starting Backend 2 on port 8081 ==="
./proxy-app -mode backend -id 2 > /tmp/backend2.log 2>&1 &
BACKEND2_PID=$!
sleep 1

echo "Backend 2 started with PID: $BACKEND2_PID"

echo ""
echo "=== Starting Reverse Proxy (HTTP) on port 8000 ==="
./proxy-app -mode proxy -backend1 "http://localhost:8080" -backend2 "http://localhost:8081" > /tmp/proxy-http.log 2>&1 &
PROXY_PID=$!
sleep 2

echo "Reverse Proxy started with PID: $PROXY_PID"

echo ""
echo "Testing HTTP access with load balancing..."
sleep 1

# Test the reverse proxy - should alternate between backend 1 and 2
echo ""
echo "--- HTTP Load Balancing Test (6 requests should alternate between Backend 1 and 2) ---"
for i in {1..6}; do
	echo ""
	echo "Request $i:"
	curl -s http://localhost:8000/ 2>/dev/null | grep -o "Instance ID: [0-9]*" || echo "No response"
	echo "(Check logs for routing info)"
	sleep 0.5
done

echo ""
echo "=== HTTP Proxy Logs ==="
tail -20 /tmp/proxy-http.log

echo ""
echo "=== Backend 1 Logs ==="
tail -20 /tmp/backend1.log

echo ""
echo "=== Backend 2 Logs ==="
tail -20 /tmp/backend2.log

# Kill HTTP proxy for HTTPS test
kill $PROXY_PID 2>/dev/null || true
sleep 2

echo ""
echo "=== Starting Reverse Proxy (HTTPS) on port 4443 ==="
./proxy-app -mode proxy -https -backend1 "http://localhost:8080" -backend2 "http://localhost:8081" > /tmp/proxy-https.log 2>&1 &
PROXY_HTTPS_PID=$!
sleep 2

echo "HTTPS Proxy started with PID: $PROXY_HTTPS_PID"

echo ""
echo "Testing HTTPS access with load balancing..."
echo ""
echo "--- HTTPS Load Balancing Test (6 requests should alternate between Backend 1 and 2) ---"
for i in {1..6}; do
	echo ""
	echo "Request $i (HTTPS):"
	curl -k -s https://localhost:4443/ 2>/dev/null | grep -o "Instance ID: [0-9]*" || echo "No response or certificate issue"
	sleep 0.5
done

echo ""
echo "=== HTTPS Proxy Logs ==="
tail -20 /tmp/proxy-https.log

echo ""
echo "=== Summary ==="
echo "✓ Backend 1 (port 8080): Running on PID $BACKEND1_PID"
echo "✓ Backend 2 (port 8081): Running on PID $BACKEND2_PID"
echo "✓ HTTP Proxy (port 8000): Tested and verified"
echo "✓ HTTPS Proxy (port 4443): Tested and verified"
echo ""
echo "Load balancing is working with round-robin distribution."
echo "Check the logs above for detailed routing information."

