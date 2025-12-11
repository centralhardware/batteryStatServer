import SwiftUI

@main
struct BatteryMonitorApp: App {
    @StateObject private var batteryService = BatteryService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(batteryService)
        }
    }
}
