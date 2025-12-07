#!/bin/bash

# Battery Health Reporter for macOS
# This script collects battery health information and sends it to the server

# Configuration
SERVER_URL="${BATTERY_SERVER_URL:-http://10.168.0.77:8321}"
ENDPOINT="/api/battery/health"

# Get device ID (hardware UUID)
DEVICE_ID=$(/usr/sbin/ioreg -rd1 -c IOPlatformExpertDevice | /usr/bin/awk '/IOPlatformUUID/ { print $3; }' | /usr/bin/tr -d '"')

# Get battery information using ioreg
IOREG_DATA=$(/usr/sbin/ioreg -r -c AppleSmartBattery)

# Extract values
CYCLE_COUNT=$(echo "$IOREG_DATA" | /usr/bin/grep '"CycleCount" =' | /usr/bin/awk '{print $3}')

# Get health percent from system_profiler (this is the official system value)
HEALTH_PERCENT=$(/usr/sbin/system_profiler SPPowerDataType | /usr/bin/grep "Maximum Capacity" | /usr/bin/awk '{print $3}' | /usr/bin/tr -d '%')

# Debug output
echo "Debug info:"
echo "  Device ID: $DEVICE_ID"
echo "  Cycle Count: $CYCLE_COUNT"
echo "  Health Percent: $HEALTH_PERCENT%"

# Validate data
if [ -z "$CYCLE_COUNT" ] || [ -z "$HEALTH_PERCENT" ]; then
    echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') - Error: Failed to get battery information"
    exit 1
fi

# Build JSON payload
JSON_PAYLOAD=$(/bin/cat <<EOF
{
  "deviceId": "$DEVICE_ID",
  "cycleCount": $CYCLE_COUNT,
  "healthPercent": $HEALTH_PERCENT
}
EOF
)

echo ""
echo "JSON Payload:"
echo "$JSON_PAYLOAD"
echo ""

# Send data to server
RESPONSE=$(/usr/bin/curl -s -w "\n%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" \
    "${SERVER_URL}${ENDPOINT}")

HTTP_CODE=$(echo "$RESPONSE" | /usr/bin/tail -n1)
BODY=$(echo "$RESPONSE" | /usr/bin/sed '$d')

if [ "$HTTP_CODE" = "201" ]; then
    echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') - Battery health reported successfully (Cycles: $CYCLE_COUNT, Health: ${HEALTH_PERCENT}%)"
    exit 0
else
    echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') - Failed to report battery health. HTTP code: $HTTP_CODE"
    echo "Response: $BODY"
    exit 1
fi
