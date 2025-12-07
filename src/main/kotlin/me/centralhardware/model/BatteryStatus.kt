package me.centralhardware.model

import kotlinx.serialization.Serializable
import java.time.LocalDateTime

@Serializable
data class BatteryHealthRequest(
    val deviceId: String,
    val cycleCount: Int,
    val healthPercent: Int,
    val manufactureDate: String? = null
)

data class BatteryHealth(
    val dateTime: LocalDateTime,
    val deviceId: String,
    val cycleCount: Int,
    val healthPercent: Int,
    val manufactureDate: String?
)
