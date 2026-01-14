package me.centralhardware.routes

import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import me.centralhardware.model.BatteryHealth
import me.centralhardware.model.BatteryHealthRequest
import me.centralhardware.repository.BatteryRepository
import me.centralhardware.service.TelegramService
import org.slf4j.LoggerFactory
import java.time.LocalDateTime

fun Route.batteryRoutes(repository: BatteryRepository, telegramService: TelegramService) {
    val logger = LoggerFactory.getLogger("BatteryRoutes")

    route("/api/battery") {
        post("/health") {
            val request = call.receive<BatteryHealthRequest>()

            val lastCycleCount = repository.getLastCycleCount(request.deviceId)

            val batteryHealth = BatteryHealth(
                dateTime = LocalDateTime.now(),
                deviceId = request.deviceId,
                cycleCount = request.cycleCount,
                healthPercent = request.healthPercent,
                currentCharge = request.currentCharge,
                temperature = request.temperature,
                isCharging = request.isCharging,
                designCapacityMah = request.designCapacityMah,
                maxCapacityMah = request.maxCapacityMah,
                voltageMv = request.voltageMv,
                currentMa = request.currentMa
            )

            repository.save(batteryHealth)

            if (lastCycleCount != null && request.cycleCount > lastCycleCount) {
                logger.info("Cycle completed for device ${request.deviceId}: $lastCycleCount -> ${request.cycleCount}")
                val stats = repository.getCycleStatistics(request.deviceId, lastCycleCount)
                if (stats != null) {
                    telegramService.sendCycleStatistics(stats)
                }
            }

            call.respond(HttpStatusCode.Created, mapOf("status" to "success"))
        }

        get("/healthcheck") {
            call.respond(HttpStatusCode.OK, mapOf("status" to "ok"))
        }
    }
}
