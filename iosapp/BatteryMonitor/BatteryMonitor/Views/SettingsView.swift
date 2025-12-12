import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("serverURL") private var serverURL = "http://10.168.0.77:8321"
    @AppStorage("deviceId") private var deviceId = ""
    @State private var showingTestResult = false
    @State private var testResultMessage = ""
    @State private var testResultSuccess = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server Configuration")) {
                    TextField("Server URL", text: $serverURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)

                    Button("Test Connection") {
                        testConnection()
                    }
                    .disabled(serverURL.isEmpty)
                }

                Section(header: Text("Device Information")) {
                    HStack {
                        Text("Device ID")
                        Spacer()
                        Text(deviceId)
                            .foregroundColor(.gray)
                            .font(.caption)
                    }

                    Button("Generate New Device ID") {
                        deviceId = UUID().uuidString
                    }
                }

                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Text("Device Model")
                        Spacer()
                        Text(UIDevice.current.model)
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Text("iOS Version")
                        Spacer()
                        Text(UIDevice.current.systemVersion)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .alert("Connection Test", isPresented: $showingTestResult) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(testResultMessage)
            }
        }
    }

    private func testConnection() {
        let apiService = APIService()

        Task {
            do {
                let success = try await apiService.testConnection()
                await MainActor.run {
                    testResultSuccess = success
                    testResultMessage = success ? "Connection successful!" : "Connection failed"
                    showingTestResult = true
                }
            } catch {
                await MainActor.run {
                    testResultSuccess = false
                    testResultMessage = "Error: \(error.localizedDescription)"
                    showingTestResult = true
                }
            }
        }
    }
}
