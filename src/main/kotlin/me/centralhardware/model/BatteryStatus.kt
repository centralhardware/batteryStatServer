package me.centralhardware.model

import kotlinx.serialization.Serializable
import java.time.LocalDateTime

@Serializable
data class BatteryHealthRequest(
    val deviceId: String,
    val cycleCount: Int,
    val healthPercent: Int,
    val currentCharge: Int,
    val temperature: Int,
    val isCharging: Boolean,
    val designCapacityMah: Int,
    val maxCapacityMah: Int,
    val voltageMv: Int,
    val currentMa: Int
)

data class BatteryHealth(
    val dateTime: LocalDateTime,
    val deviceId: String,
    val cycleCount: Int,
    val healthPercent: Int,
    val currentCharge: Int,
    val temperature: Int,
    val isCharging: Boolean,
    val designCapacityMah: Int,
    val maxCapacityMah: Int,
    val voltageMv: Int,
    val currentMa: Int
)
