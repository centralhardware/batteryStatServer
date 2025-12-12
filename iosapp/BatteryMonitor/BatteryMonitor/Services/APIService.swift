import Foundation
import UIKit

class APIService {
    private let baseURL: String
    private let deviceId: String

    init() {
        // Читаем URL сервера из UserDefaults или используем значение по умолчанию
        self.baseURL = UserDefaults.standard.string(forKey: "serverURL") ?? "http://10.168.0.77:8321"

        // Используем UUID устройства как deviceId
        if let savedDeviceId = UserDefaults.standard.string(forKey: "deviceId") {
            self.deviceId = savedDeviceId
        } else {
            let newDeviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            UserDefaults.standard.set(newDeviceId, forKey: "deviceId")
            self.deviceId = newDeviceId
        }
    }

    func sendBatteryData(_ batteryInfo: BatteryInfo) async throws {
        guard let url = URL(string: "\(baseURL)/api/battery/health") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let batteryRequest = batteryInfo.toRequest(deviceId: deviceId)
        request.httpBody = try JSONEncoder().encode(batteryRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    func testConnection() async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/api/battery/healthcheck") else {
            throw APIError.invalidURL
        }

        let (_, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        return httpResponse.statusCode == 200
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        }
    }
}
