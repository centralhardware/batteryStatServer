package me.centralhardware.service

import io.ktor.client.*
import io.ktor.client.engine.cio.*
import io.ktor.client.request.forms.*
import io.ktor.http.*
import kotlinx.coroutines.runBlocking
import org.slf4j.LoggerFactory

class TelegramService(
    private val botToken: String = System.getenv("TELEGRAM_BOT_TOKEN") ?: "",
    private val chatId: String = System.getenv("TELEGRAM_CHAT_ID") ?: ""
) {
    private val logger = LoggerFactory.getLogger(TelegramService::class.java)
    private val client = HttpClient(CIO)

    fun sendCycleStatistics(stats: CycleStatistics) {
        val activePercent = if (stats.durationMinutes > 0) {
            (stats.activeMinutes * 100.0 / stats.durationMinutes)
        } else 0.0

        val message = buildString {
            appendLine("Цикл батареи завершён")
            appendLine()
            appendLine("Устройство: ${stats.deviceId}")
            appendLine("Номер цикла: ${stats.cycleCount}")
            appendLine("Здоровье: ${stats.healthPercent}%")
            appendLine()
            appendLine("Статистика цикла:")
            appendLine("  Длительность: ${formatDuration(stats.durationMinutes)}")
            appendLine("  Активное время: ${formatDuration(stats.activeMinutes)} (${String.format("%.1f", activePercent)}%)")
            appendLine("  На зарядке: ${formatDuration(stats.chargingMinutes)}")
            appendLine("  Заряд: ${stats.startCharge}% -> ${stats.endCharge}%")
            appendLine("  Записей: ${stats.recordCount}")
        }

        runBlocking {
            try {
                client.submitForm(
                    url = "https://api.telegram.org/bot$botToken/sendMessage",
                    formParameters = parameters {
                        append("chat_id", chatId)
                        append("text", message)
                    }
                )
                logger.info("Telegram notification sent for cycle ${stats.cycleCount} of device ${stats.deviceId}")
            } catch (e: Exception) {
                logger.error("Failed to send Telegram notification: ${e.message}", e)
            }
        }
    }

    private fun formatDuration(minutes: Long): String {
        val hours = minutes / 60
        val mins = minutes % 60
        return if (hours > 0) "${hours}ч ${mins}мин" else "${mins}мин"
    }
}

data class CycleStatistics(
    val deviceId: String,
    val cycleCount: Int,
    val healthPercent: Int,
    val durationMinutes: Long,
    val activeMinutes: Long,
    val chargingMinutes: Long,
    val startCharge: Int,
    val endCharge: Int,
    val recordCount: Int
)
