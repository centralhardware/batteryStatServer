package me.centralhardware.repository

import com.clickhouse.jdbc.ClickHouseDataSource
import kotliquery.queryOf
import kotliquery.sessionOf
import me.centralhardware.model.BatteryHealth
import org.slf4j.LoggerFactory
import java.sql.Timestamp

class BatteryRepository(clickhouseUrl: String) {
    private val logger = LoggerFactory.getLogger(BatteryRepository::class.java)
    private val dataSource: ClickHouseDataSource

    init {
        dataSource = ClickHouseDataSource(clickhouseUrl)
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
                        max_capacity_mah
                    ) VALUES (
                        toDateTime(?),
                        toString(?),
                        toUInt32(?),
                        toUInt8(?),
                        toUInt8(?),
                        toInt16(?),
                        toUInt8(?),
                        toUInt16(?),
                        toUInt16(?)
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
                    health.maxCapacityMah
                ).asUpdate
            )

            logger.info("Battery health saved: device=${health.deviceId}, cycles=${health.cycleCount}, health=${health.healthPercent}%, charge=${health.currentCharge}%, temp=${health.temperature}°C, charging=${health.isCharging}")
        }
    }
}
