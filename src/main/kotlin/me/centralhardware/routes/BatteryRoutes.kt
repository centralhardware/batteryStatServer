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
                maxCapacityMah = request.maxCapacityMah,
                voltageMv = request.voltageMv,
                currentMa = request.currentMa,
                avgTimeToEmpty = request.avgTimeToEmpty,
                avgTimeToFull = request.avgTimeToFull,
                externalConnected = request.externalConnected,
                fullyCharged = request.fullyCharged,
                nominalChargeCapacity = request.nominalChargeCapacity,
                rawCurrentCapacity = request.rawCurrentCapacity,
                rawBatteryVoltage = request.rawBatteryVoltage,
                virtualTemperature = request.virtualTemperature,
                cellVoltage1 = request.cellVoltage1,
                cellVoltage2 = request.cellVoltage2,
                cellVoltage3 = request.cellVoltage3,
                atCriticalLevel = request.atCriticalLevel,
                batteryCellDisconnectCount = request.batteryCellDisconnectCount,
                adapterWatts = request.adapterWatts,
                adapterName = request.adapterName,
                adapterVoltage = request.adapterVoltage,
                designCycleCount = request.designCycleCount
            )

            repository.save(batteryHealth)

            call.respond(HttpStatusCode.Created, mapOf("status" to "success"))
        }

        get("/healthcheck") {
            call.respond(HttpStatusCode.OK, mapOf("status" to "ok"))
        }
    }
}
