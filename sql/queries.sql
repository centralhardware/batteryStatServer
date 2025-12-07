-- Useful ClickHouse queries for battery_health table

-- View latest battery health records
SELECT * FROM battery_health
ORDER BY date_time DESC
LIMIT 10;

-- View latest records for each device
SELECT
    device_id,
    date_time,
    cycle_count,
    round((max_capacity * 100.0) / design_capacity, 2) as health_percent
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY device_id ORDER BY date_time DESC) as rn
    FROM battery_health
) WHERE rn = 1
ORDER BY device_id;

-- Battery health percentage over time for specific device
SELECT
    date_time,
    cycle_count,
    round((max_capacity * 100.0) / design_capacity, 2) as health_percent
FROM battery_health
WHERE device_id = 'YOUR_DEVICE_ID'
ORDER BY date_time DESC
LIMIT 30;

-- Daily average statistics for the last 30 days
SELECT
    toDate(date_time) as date,
    round(avg(cycle_count), 0) as avg_cycles,
    round(avg((max_capacity * 100.0) / design_capacity), 2) as avg_health_percent,
    round(avg(temperature), 2) as avg_temp_celsius,
    count(*) as measurements
FROM battery_health
WHERE date_time >= now() - INTERVAL 30 DAY
GROUP BY date
ORDER BY date DESC;

-- Battery degradation tracking (weekly)
SELECT
    toStartOfWeek(date_time) as week,
    round(avg((max_capacity * 100.0) / design_capacity), 2) as avg_health_percent,
    round(max((max_capacity * 100.0) / design_capacity), 2) as max_health_percent,
    round(min((max_capacity * 100.0) / design_capacity), 2) as min_health_percent,
    round(avg(cycle_count), 0) as avg_cycles
FROM battery_health
GROUP BY week
ORDER BY week DESC
LIMIT 12;

-- Cycle count growth rate
SELECT
    toDate(date_time) as date,
    max(cycle_count) - min(cycle_count) as cycles_added,
    round(avg((max_capacity * 100.0) / design_capacity), 2) as avg_health
FROM battery_health
GROUP BY date
ORDER BY date DESC
LIMIT 30;


-- Hourly battery health check frequency
SELECT
    toHour(date_time) as hour,
    count(*) as measurements,
    round(avg((max_capacity * 100.0) / design_capacity), 2) as avg_health
FROM battery_health
WHERE date_time >= now() - INTERVAL 7 DAY
GROUP BY hour
ORDER BY hour;

-- Capacity degradation over time
SELECT
    toStartOfMonth(date_time) as month,
    round(avg(max_capacity), 0) as avg_max_capacity,
    round(avg(current_capacity), 0) as avg_current_capacity,
    round(avg(design_capacity), 0) as avg_design_capacity
FROM battery_health
GROUP BY month
ORDER BY month DESC;

-- Latest battery health summary for all devices
SELECT
    device_id,
    date_time,
    cycle_count,
    design_capacity,
    max_capacity,
    round((max_capacity * 100.0) / design_capacity, 2) as health_percent,
    current_capacity,
    round((current_capacity * 100.0) / max_capacity, 2) as current_charge_percent,
    manufacture_date
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY device_id ORDER BY date_time DESC) as rn
    FROM battery_health
) WHERE rn = 1
ORDER BY device_id;

-- Count records per device
SELECT
    device_id,
    count(*) as records,
    min(date_time) as first_record,
    max(date_time) as last_record
FROM battery_health
GROUP BY device_id
ORDER BY device_id;
