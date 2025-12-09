package me.centralhardware.routes

import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import me.centralhardware.model.BatteryHealth
import me.centralhardware.model.BatteryHealthRequest
import me.centralhardware.repository.BatteryRepository
import java.time.LocalDateTime

fun Route.batteryRoutes(repository: BatteryRepository) {
    route("/api/battery") {
        post("/health") {
            val request = call.receive<BatteryHealthRequest>()

            val batteryHealth = BatteryHealth(
                dateTime = LocalDateTime.now(),
                deviceId = request.deviceId,
                cycleCount = request.cycleCount,
                healthPercent = request.healthPercent,
                currentCharge = request.currentCharge,
                temperature = request.temperature,
                isCharging = request.isCharging,
                designCapacityMah = request.designCapacityMah,
                maxCapacityMah = request.maxCapacityMah
            )

            repository.save(batteryHealth)

            call.respond(HttpStatusCode.Created, mapOf("status" to "success"))
        }

        get("/healthcheck") {
            call.respond(HttpStatusCode.OK, mapOf("status" to "ok"))
        }
    }
}
