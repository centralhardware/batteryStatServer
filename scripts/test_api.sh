#!/bin/bash

# Test script for Battery Health API

SERVER_URL="${BATTERY_SERVER_URL:-http://localhost:8080}"

echo "Testing Battery Health API at $SERVER_URL"
echo "=========================================="
echo ""

# Test 1: Health check
echo "Test 1: Health check endpoint"
echo "GET $SERVER_URL/api/battery/healthcheck"
RESPONSE=$(curl -s -w "\n%{http_code}" "$SERVER_URL/api/battery/healthcheck")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Health check passed"
    echo "  Response: $BODY"
else
    echo "✗ Health check failed (HTTP $HTTP_CODE)"
    echo "  Response: $BODY"
    exit 1
fi

echo ""
echo "=========================================="
echo ""

# Test 2: Send battery health data
echo "Test 2: Send battery health data"
echo "POST $SERVER_URL/api/battery/health"

TEST_DATA='{
  "deviceId": "test-device-001",
  "cycleCount": 123,
  "healthPercent": 96,
  "manufactureDate": "2022-01-15"
}'

echo "Request body:"
echo "$TEST_DATA" | jq .

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d "$TEST_DATA" \
    "$SERVER_URL/api/battery/health")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "201" ]; then
    echo "✓ Data sent successfully"
    echo "  Response: $BODY"
else
    echo "✗ Failed to send data (HTTP $HTTP_CODE)"
    echo "  Response: $BODY"
    exit 1
fi

echo ""
echo "=========================================="
echo ""

# Test 3: Send another record with different values
echo "Test 3: Send data with minimal fields"

MINIMAL_DATA='{
  "deviceId": "test-device-002",
  "cycleCount": 456,
  "healthPercent": 90
}'

echo "Request body:"
echo "$MINIMAL_DATA" | jq .

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d "$MINIMAL_DATA" \
    "$SERVER_URL/api/battery/health")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "201" ]; then
    echo "✓ Minimal data sent successfully"
    echo "  Response: $BODY"
else
    echo "✗ Failed to send minimal data (HTTP $HTTP_CODE)"
    echo "  Response: $BODY"
    exit 1
fi

echo ""
echo "=========================================="
echo ""
echo "All tests passed! ✓"
echo ""
echo "You can verify the data in ClickHouse with:"
echo "  clickhouse-client --query \"SELECT * FROM battery_health ORDER BY date_time DESC LIMIT 5\""
