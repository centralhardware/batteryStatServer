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
                        max_capacity_mah,
                        voltage_mv,
                        current_ma,
                        avg_time_to_empty,
                        avg_time_to_full,
                        external_connected,
                        fully_charged,
                        nominal_charge_capacity,
                        raw_current_capacity,
                        raw_battery_voltage,
                        virtual_temperature,
                        cell_voltage_1,
                        cell_voltage_2,
                        cell_voltage_3,
                        at_critical_level,
                        battery_cell_disconnect_count,
                        adapter_watts,
                        adapter_name,
                        adapter_voltage,
                        design_cycle_count
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
                        toInt16(?),
                        toUInt16(?),
                        toUInt16(?),
                        ?,
                        ?,
                        toUInt16(?),
                        toUInt16(?),
                        toUInt16(?),
                        toFloat32(?),
                        toUInt16(?),
                        toUInt16(?),
                        toUInt16(?),
                        ?,
                        toUInt16(?),
                        toUInt16(?),
                        toString(?),
                        toUInt32(?),
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
                    health.maxCapacityMah,
                    health.voltageMv,
                    health.currentMa,
                    health.avgTimeToEmpty,
                    health.avgTimeToFull,
                    health.externalConnected,
                    health.fullyCharged,
                    health.nominalChargeCapacity,
                    health.rawCurrentCapacity,
                    health.rawBatteryVoltage,
                    health.virtualTemperature,
                    health.cellVoltage1,
                    health.cellVoltage2,
                    health.cellVoltage3,
                    health.atCriticalLevel,
                    health.batteryCellDisconnectCount,
                    health.adapterWatts,
                    health.adapterName,
                    health.adapterVoltage,
                    health.designCycleCount
                ).asUpdate
            )

            logger.info("Battery health saved: device=${health.deviceId}, cycles=${health.cycleCount}, health=${health.healthPercent}%, charge=${health.currentCharge}%, temp=${health.temperature}°C, charging=${health.isCharging}")
        }
    }
}
