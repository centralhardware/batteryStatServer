import Foundation
import UIKit
import Combine

class BatteryService: ObservableObject {
    @Published var batteryInfo: BatteryInfo?
    @Published var isMonitoring = false
    @Published var lastUpdateTime: Date?
    @Published var errorMessage: String?

    private var timer: Timer?
    private let apiService = APIService()

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        updateBatteryInfo()
    }

    func startMonitoring(interval: TimeInterval = 60) {
        guard !isMonitoring else { return }

        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.updateAndSendBatteryInfo()
        }
        updateAndSendBatteryInfo()
    }

    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
    }

    func updateBatteryInfo() {
        let device = UIDevice.current
        let level = device.batteryLevel
        let state = device.batteryState

        // Получаем данные из IOKit
        let iokitData = IOKitBatteryInfo.getBatteryInfo() ?? [:]

        // Базовые данные от UIDevice
        let isCharging = state == .charging || state == .full

        // Текущий заряд в процентах из UIDevice (более надежно)
        let currentCharge: Int
        if level >= 0 {
            currentCharge = Int(level * 100)
        } else {
            // Если UIDevice не дал значение, пытаемся из IOKit
            if let currentCap = iokitData["currentCapacity"] as? Int,
               let maxCap = iokitData["maxCapacity"] as? Int,
               maxCap > 0 {
                currentCharge = (currentCap * 100) / maxCap
            } else {
                currentCharge = 0
            }
        }

        // Cycle Count - только из IOKit, иначе 0
        let cycleCount = iokitData["cycleCount"] as? Int ?? 0

        // Design Capacity - из IOKit, иначе 0
        let designCapacity = iokitData["designCapacity"] as? Int ?? 0

        // Max Capacity - из IOKit, иначе 0
        let maxCapacity = iokitData["maxCapacity"] as? Int ?? 0

        // Health Percent - считаем на основе реальных данных
        let healthPercent: Int
        if designCapacity > 0 && maxCapacity > 0 {
            healthPercent = min(100, (maxCapacity * 100) / designCapacity)
        } else {
            healthPercent = 0
        }

        // Температура - из IOKit если есть, иначе 0
        // IOKit может давать температуру в сантиградусах (0.01 градуса)
        let temperature: Float
        if let temp = iokitData["temperature"] as? Int {
            // Конвертируем из сантиградусов в градусы
            temperature = Float(temp) / 100.0
        } else {
            temperature = 0.0
        }

        // Напряжение - из IOKit в милливольтах
        let voltage: Int
        if let voltageValue = iokitData["voltage"] as? Int {
            // IOKit дает напряжение в милливольтах
            voltage = voltageValue
        } else {
            voltage = 0
        }

        // Ток - из IOKit в миллиамперах
        let current: Int
        if let currentValue = iokitData["current"] as? Int {
            // IOKit дает ток в миллиамперах (может быть отрицательным при разрядке)
            current = currentValue
        } else {
            current = 0
        }

        let batteryInfo = BatteryInfo(
            cycleCount: cycleCount,
            healthPercent: healthPercent,
            currentCharge: currentCharge,
            temperature: temperature,
            isCharging: isCharging,
            designCapacity: designCapacity,
            maxCapacity: maxCapacity,
            voltage: voltage,
            current: current
        )

        DispatchQueue.main.async {
            self.batteryInfo = batteryInfo
        }
    }

    private func updateAndSendBatteryInfo() {
        updateBatteryInfo()

        guard let info = batteryInfo else { return }

        Task {
            do {
                try await apiService.sendBatteryData(info)
                await MainActor.run {
                    self.lastUpdateTime = Date()
                    self.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
