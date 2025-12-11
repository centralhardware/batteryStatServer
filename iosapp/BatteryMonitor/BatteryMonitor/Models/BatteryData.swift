import Foundation

struct BatteryHealthRequest: Codable {
    let deviceId: String
    let cycleCount: Int
    let healthPercent: Int
    let currentCharge: Int
    let temperature: Float
    let isCharging: Bool
    let designCapacityMah: Int
    let maxCapacityMah: Int
    let voltageMv: Int
    let currentMa: Int
}

struct BatteryInfo {
    let cycleCount: Int
    let healthPercent: Int
    let currentCharge: Int
    let temperature: Float
    let isCharging: Bool
    let designCapacity: Int
    let maxCapacity: Int
    let voltage: Int
    let current: Int

    func toRequest(deviceId: String) -> BatteryHealthRequest {
        BatteryHealthRequest(
            deviceId: deviceId,
            cycleCount: cycleCount,
            healthPercent: healthPercent,
            currentCharge: currentCharge,
            temperature: temperature,
            isCharging: isCharging,
            designCapacityMah: designCapacity,
            maxCapacityMah: maxCapacity,
            voltageMv: voltage,
            currentMa: current
        )
    }
}
