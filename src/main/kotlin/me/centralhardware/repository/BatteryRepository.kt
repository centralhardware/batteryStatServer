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
                        health_percent
                    ) VALUES (
                        toDateTime(?),
                        toString(?),
                        toUInt32(?),
                        toUInt8(?)
                    )
                    """.trimIndent(),
                    Timestamp.valueOf(health.dateTime),
                    health.deviceId,
                    health.cycleCount,
                    health.healthPercent
                ).asUpdate
            )

            logger.info("Battery health saved: device=${health.deviceId}, cycles=${health.cycleCount}, health=${health.healthPercent}%")
        }
    }
}
