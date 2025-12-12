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

        // Базовые данные от UIDevice
        let isCharging = state == .charging || state == .full

        // Текущий заряд в процентах из UIDevice
        let currentCharge: Int
        if level >= 0 {
            currentCharge = Int(level * 100)
        } else {
            currentCharge = 0
        }

        // На iOS через публичные API недоступны:
        // - cycle count
        // - health
        // - temperature
        // - voltage
        // - current
        // Устанавливаем значения по умолчанию
        let cycleCount = 0
        let designCapacity = 0
        let maxCapacity = 0
        let healthPercent = 100 // Предполагаем 100% если нет данных
        let temperature: Float = 0.0
        let voltage = 0
        let current = 0

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
