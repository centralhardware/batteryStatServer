package me.centralhardware.model

import kotlinx.serialization.Serializable
import java.time.LocalDateTime

@Serializable
data class BatteryHealthRequest(
    val deviceId: String,
    val cycleCount: Int,
    val healthPercent: Int,
    val currentCharge: Int,
    val temperature: Float,
    val isCharging: Boolean,
    val designCapacityMah: Int,
    val maxCapacityMah: Int,
    val voltageMv: Int,
    val currentMa: Int,
    val avgTimeToEmpty: Int,
    val avgTimeToFull: Int,
    val externalConnected: Boolean,
    val fullyCharged: Boolean,
    val nominalChargeCapacity: Int,
    val rawCurrentCapacity: Int,
    val rawBatteryVoltage: Int,
    val virtualTemperature: Float,
    val cellVoltage1: Int,
    val cellVoltage2: Int,
    val cellVoltage3: Int,
    val atCriticalLevel: Boolean,
    val batteryCellDisconnectCount: Int,
    val adapterWatts: Int,
    val adapterName: String,
    val adapterVoltage: Int,
    val designCycleCount: Int
)

data class BatteryHealth(
    val dateTime: LocalDateTime,
    val deviceId: String,
    val cycleCount: Int,
    val healthPercent: Int,
    val currentCharge: Int,
    val temperature: Float,
    val isCharging: Boolean,
    val designCapacityMah: Int,
    val maxCapacityMah: Int,
    val voltageMv: Int,
    val currentMa: Int,
    val avgTimeToEmpty: Int,
    val avgTimeToFull: Int,
    val externalConnected: Boolean,
    val fullyCharged: Boolean,
    val nominalChargeCapacity: Int,
    val rawCurrentCapacity: Int,
    val rawBatteryVoltage: Int,
    val virtualTemperature: Float,
    val cellVoltage1: Int,
    val cellVoltage2: Int,
    val cellVoltage3: Int,
    val atCriticalLevel: Boolean,
    val batteryCellDisconnectCount: Int,
    val adapterWatts: Int,
    val adapterName: String,
    val adapterVoltage: Int,
    val designCycleCount: Int
)
