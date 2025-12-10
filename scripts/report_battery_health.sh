#!/bin/bash

# Battery Health Reporter for macOS
# This script collects battery health information and sends it to the server

# Configuration
SERVER_URL="${https//bs.centralhardware.me}"
ENDPOINT="/api/battery/health"

# Get device ID (hardware UUID)
DEVICE_ID=$(/usr/sbin/ioreg -rd1 -c IOPlatformExpertDevice | /usr/bin/awk '/IOPlatformUUID/ { print $3; }' | /usr/bin/tr -d '"')

# Get battery information using ioreg
IOREG_DATA=$(/usr/sbin/ioreg -r -c AppleSmartBattery)

# Extract values
CYCLE_COUNT=$(echo "$IOREG_DATA" | /usr/bin/grep '"CycleCount" =' | /usr/bin/awk '{print $3}')
CURRENT_CHARGE=$(echo "$IOREG_DATA" | /usr/bin/grep '"CurrentCapacity" =' | /usr/bin/awk '{print $3}')
MAX_CAPACITY=$(echo "$IOREG_DATA" | /usr/bin/grep '"MaxCapacity" =' | /usr/bin/awk '{print $3}')
TEMPERATURE=$(echo "$IOREG_DATA" | /usr/bin/grep '"Temperature" =' | /usr/bin/awk '{print $3}')
IS_CHARGING=$(echo "$IOREG_DATA" | /usr/bin/grep '"IsCharging" =' | /usr/bin/awk '{print $3}')
DESIGN_CAPACITY_MAH=$(echo "$IOREG_DATA" | /usr/bin/grep '"DesignCapacity" =' | /usr/bin/awk '{print $3}')
MAX_CAPACITY_MAH=$(echo "$IOREG_DATA" | /usr/bin/grep '"AppleRawMaxCapacity" =' | /usr/bin/awk '{print $3}')
VOLTAGE=$(echo "$IOREG_DATA" | /usr/bin/grep '"Voltage" =' | /usr/bin/awk '{print $3}')
CURRENT=$(echo "$IOREG_DATA" | /usr/bin/grep '"InstantAmperage" =' | /usr/bin/awk '{print $3}')

# Get health percent from system_profiler (this is the official system value)
HEALTH_PERCENT=$(/usr/sbin/system_profiler SPPowerDataType | /usr/bin/grep "Maximum Capacity" | /usr/bin/awk '{print $3}' | /usr/bin/tr -d '%')

# Calculate current charge percentage
if [ -n "$CURRENT_CHARGE" ] && [ -n "$MAX_CAPACITY" ] && [ "$MAX_CAPACITY" -gt 0 ]; then
    CHARGE_PERCENT=$((CURRENT_CHARGE * 100 / MAX_CAPACITY))
else
    CHARGE_PERCENT=0
fi

# Convert temperature from centi-Celsius to Celsius (divide by 100)
if [ -n "$TEMPERATURE" ]; then
    TEMP_CELSIUS=$(echo "scale=2; $TEMPERATURE / 100" | /usr/bin/bc)
else
    TEMP_CELSIUS=0
fi

# Convert IsCharging to boolean
if [ "$IS_CHARGING" = "Yes" ]; then
    IS_CHARGING_BOOL="true"
else
    IS_CHARGING_BOOL="false"
fi

# Voltage is already in mV
if [ -z "$VOLTAGE" ]; then
    VOLTAGE=0
fi

# Convert InstantAmperage from unsigned to signed integer
# ioreg returns negative values as large unsigned 64-bit numbers
if [ -n "$CURRENT" ]; then
    # Use Python to convert unsigned to signed int64
    CURRENT=$(/usr/bin/python3 -c "import sys; val = $CURRENT; print(val if val <= 9223372036854775807 else val - 18446744073709551616)")
else
    CURRENT=0
fi

# Debug output
echo "Debug info:"
echo "  Device ID: $DEVICE_ID"
echo "  Cycle Count: $CYCLE_COUNT"
echo "  Health Percent: $HEALTH_PERCENT%"
echo "  Current Charge: $CHARGE_PERCENT%"
echo "  Temperature: ${TEMP_CELSIUS}°C"
echo "  Is Charging: $IS_CHARGING_BOOL"
echo "  Design Capacity: ${DESIGN_CAPACITY_MAH} mAh"
echo "  Max Capacity: ${MAX_CAPACITY_MAH} mAh"
echo "  Voltage: ${VOLTAGE} mV"
echo "  Current: ${CURRENT} mA"

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
  "healthPercent": $HEALTH_PERCENT,
  "currentCharge": $CHARGE_PERCENT,
  "temperature": $TEMP_CELSIUS,
  "isCharging": $IS_CHARGING_BOOL,
  "designCapacityMah": ${DESIGN_CAPACITY_MAH:-0},
  "maxCapacityMah": ${MAX_CAPACITY_MAH:-0},
  "voltageMv": ${VOLTAGE:-0},
  "currentMa": ${CURRENT:-0}
}
EOF
)

# Send data to server
RESPONSE=$(/usr/bin/curl -s -w "\n%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" \
    "${SERVER_URL}${ENDPOINT}")

HTTP_CODE=$(echo "$RESPONSE" | /usr/bin/tail -n1)
BODY=$(echo "$RESPONSE" | /usr/bin/sed '$d')

if [ "$HTTP_CODE" = "201" ]; then
    echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') - Battery health reported successfully"
    exit 0
else
    echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') - Failed to report battery health. HTTP code: $HTTP_CODE"
    echo "Response: $BODY"
    exit 1
fi
