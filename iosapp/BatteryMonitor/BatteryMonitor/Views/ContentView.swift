import SwiftUI

struct ContentView: View {
    @EnvironmentObject var batteryService: BatteryService
    @State private var showSettings = false
    @State private var updateInterval: Double = 60

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let info = batteryService.batteryInfo {
                        BatteryStatusCard(info: info)
                        BatteryDetailsView(info: info)
                    } else {
                        Text("Loading battery information...")
                            .foregroundColor(.gray)
                    }

                    MonitoringControlView(
                        isMonitoring: $batteryService.isMonitoring,
                        updateInterval: $updateInterval,
                        onStartStop: {
                            if batteryService.isMonitoring {
                                batteryService.stopMonitoring()
                            } else {
                                batteryService.startMonitoring(interval: updateInterval)
                            }
                        }
                    )

                    if let lastUpdate = batteryService.lastUpdateTime {
                        LastUpdateView(date: lastUpdate)
                    }

                    if let error = batteryService.errorMessage {
                        ErrorView(message: error)
                    }
                }
                .padding()
            }
            .navigationTitle("Battery Monitor")
            .navigationBarItems(trailing: Button(action: {
                showSettings = true
            }) {
                Image(systemName: "gear")
            })
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

struct BatteryStatusCard: View {
    let info: BatteryInfo

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: info.isCharging ? "bolt.fill" : "battery.100")
                    .font(.system(size: 50))
                    .foregroundColor(info.isCharging ? .green : batteryColor)

                VStack(alignment: .leading) {
                    Text("\(info.currentCharge)%")
                        .font(.system(size: 48, weight: .bold))
                    Text(info.isCharging ? "Charging" : "Discharging")
                        .foregroundColor(.gray)
                }
            }

            HStack {
                VStack {
                    Text("Health")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(info.healthPercent)%")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                VStack {
                    Text("Cycles")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(info.cycleCount)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }

    private var batteryColor: Color {
        if info.currentCharge > 50 {
            return .green
        } else if info.currentCharge > 20 {
            return .orange
        } else {
            return .red
        }
    }
}

struct BatteryDetailsView: View {
    let info: BatteryInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Battery Details")
                .font(.headline)

            DetailRow(label: "Design Capacity", value: "\(info.designCapacity) mAh")
            DetailRow(label: "Max Capacity", value: "\(info.maxCapacity) mAh")
            DetailRow(label: "Voltage", value: "\(info.voltage) mV")
            DetailRow(label: "Current", value: "\(info.current) mA")
            DetailRow(label: "Temperature", value: String(format: "%.1f°C", info.temperature))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct MonitoringControlView: View {
    @Binding var isMonitoring: Bool
    @Binding var updateInterval: Double
    let onStartStop: () -> Void

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Update Interval")
                    .foregroundColor(.gray)
                Spacer()
                Text("\(Int(updateInterval))s")
                    .fontWeight(.medium)
            }

            Slider(value: $updateInterval, in: 10...300, step: 10)
                .disabled(isMonitoring)

            Button(action: onStartStop) {
                Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isMonitoring ? Color.red : Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

struct LastUpdateView: View {
    let date: Date

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("Last update: \(formatDate(date))")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct ErrorView: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(10)
    }
}
