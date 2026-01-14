package me.centralhardware.repository

import com.clickhouse.jdbc.ClickHouseDataSource
import kotliquery.queryOf
import kotliquery.sessionOf
import me.centralhardware.model.BatteryHealth
import me.centralhardware.service.CycleStatistics
import org.slf4j.LoggerFactory
import java.sql.Timestamp

class BatteryRepository(clickhouseUrl: String) {
    private val logger = LoggerFactory.getLogger(BatteryRepository::class.java)
    private val dataSource: ClickHouseDataSource

    init {
        dataSource = ClickHouseDataSource(clickhouseUrl)
    }

    fun getLastCycleCount(deviceId: String): Int? {
        return sessionOf(dataSource).use { session ->
            session.run(
                queryOf(
                    """
                    SELECT cycle_count
                    FROM battery_health
                    WHERE device_id = ?
                    ORDER BY date_time DESC
                    LIMIT 1
                    """.trimIndent(),
                    deviceId
                ).map { row -> row.int("cycle_count") }.asSingle
            )
        }
    }

    fun getCycleStatistics(deviceId: String, cycleCount: Int): CycleStatistics? {
        return sessionOf(dataSource).use { session ->
            session.run(
                queryOf(
                    """
                    SELECT
                        device_id,
                        ? as cycle_count,
                        any(health_percent) as health_percent,
                        dateDiff('minute', min(date_time), max(date_time)) as duration_minutes,
                        uniq(toStartOfMinute(date_time)) as active_minutes,
                        uniqIf(toStartOfMinute(date_time), is_charging = 1) as charging_minutes,
                        argMin(current_charge, date_time) as start_charge,
                        argMax(current_charge, date_time) as end_charge,
                        count() as record_count
                    FROM battery_health
                    WHERE device_id = ? AND cycle_count = ?
                    GROUP BY device_id
                    """.trimIndent(),
                    cycleCount,
                    deviceId,
                    cycleCount
                ).map { row ->
                    CycleStatistics(
                        deviceId = row.string("device_id"),
                        cycleCount = row.int("cycle_count"),
                        healthPercent = row.int("health_percent"),
                        durationMinutes = row.long("duration_minutes"),
                        activeMinutes = row.long("active_minutes"),
                        chargingMinutes = row.long("charging_minutes"),
                        startCharge = row.int("start_charge"),
                        endCharge = row.int("end_charge"),
                        recordCount = row.int("record_count")
                    )
                }.asSingle
            )
        }
    }

    fun save(health: BatteryHealth) {
        sessionOf(dataSource).use { session ->
            session.run(
                queryOf(
                    """
                    INSERT INTO battery_health (
                        date_time,
                        device_id,
                        cycle_count,
                        health_percent,
                        current_charge,
                        temperature,
                        is_charging,
                        design_capacity_mah,
                        max_capacity_mah,
                        voltage_mv,
                        current_ma
                    ) VALUES (
                        toDateTime(?),
                        toString(?),
                        toUInt32(?),
                        toUInt8(?),
                        toUInt8(?),
                        toFloat32(?),
                        toUInt8(?),
                        toUInt16(?),
                        toUInt16(?),
                        toUInt16(?),
                        toInt16(?)
                    )
                    """.trimIndent(),
                    Timestamp.valueOf(health.dateTime),
                    health.deviceId,
                    health.cycleCount,
                    health.healthPercent,
                    health.currentCharge,
                    health.temperature,
                    if (health.isCharging) 1 else 0,
                    health.designCapacityMah,
                    health.maxCapacityMah,
                    health.voltageMv,
                    health.currentMa
                ).asUpdate
            )

            logger.info("Battery health saved: device=${health.deviceId}, cycles=${health.cycleCount}, health=${health.healthPercent}%, charge=${health.currentCharge}%, temp=${health.temperature}°C, charging=${health.isCharging}")
        }
    }
}
