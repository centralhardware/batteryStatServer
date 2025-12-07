#!/bin/bash

# Battery Health Reporter for macOS
# This script collects battery health information and sends it to the server

# Configuration
SERVER_URL="${BATTERY_SERVER_URL:-http://localhost:8080}"
ENDPOINT="/api/battery/health"

# Get device ID (hardware UUID)
DEVICE_ID=$(ioreg -rd1 -c IOPlatformExpertDevice | awk '/IOPlatformUUID/ { print $3; }' | tr -d '"')

# Get battery information using ioreg
IOREG_DATA=$(ioreg -r -c AppleSmartBattery)

# Extract values
CYCLE_COUNT=$(echo "$IOREG_DATA" | grep '"CycleCount" =' | awk '{print $3}')
MANUFACTURE_DATE=$(echo "$IOREG_DATA" | grep '"ManufactureDate" =' | awk '{print $3}' | tr -d '"')

# Get health percent from system_profiler (this is the official system value)
HEALTH_PERCENT=$(system_profiler SPPowerDataType | grep "Maximum Capacity" | awk '{print $3}' | tr -d '%')

# Debug output
echo "Debug info:"
echo "  Device ID: $DEVICE_ID"
echo "  Cycle Count: $CYCLE_COUNT"
echo "  Health Percent: $HEALTH_PERCENT%"
echo "  Manufacture Date: $MANUFACTURE_DATE"

# Validate data
if [ -z "$CYCLE_COUNT" ] || [ -z "$HEALTH_PERCENT" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Failed to get battery information"
    exit 1
fi

# Build JSON payload
if [ -z "$MANUFACTURE_DATE" ] || [ "$MANUFACTURE_DATE" = "0" ]; then
    MFG_DATE_JSON="null"
else
    MFG_DATE_JSON="\"$MANUFACTURE_DATE\""
fi

JSON_PAYLOAD=$(cat <<EOF
{
  "deviceId": "$DEVICE_ID",
  "cycleCount": $CYCLE_COUNT,
  "healthPercent": $HEALTH_PERCENT,
  "manufactureDate": $MFG_DATE_JSON
}
EOF
)

echo ""
echo "JSON Payload:"
echo "$JSON_PAYLOAD"
echo ""

# Send data to server
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" \
    "${SERVER_URL}${ENDPOINT}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "201" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Battery health reported successfully (Cycles: $CYCLE_COUNT, Health: ${HEALTH_PERCENT}%)"
    exit 0
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Failed to report battery health. HTTP code: $HTTP_CODE"
    echo "Response: $BODY"
    exit 1
fi
