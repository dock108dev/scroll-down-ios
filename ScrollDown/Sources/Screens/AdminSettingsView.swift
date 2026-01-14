import SwiftUI
import OSLog

/// Beta-only admin settings screen
/// Provides access to time override and other debug features
///
/// Access: Hidden gesture or debug menu only
/// Production: Should never appear in release builds
struct AdminSettingsView: View {
    @EnvironmentObject private var appConfig: AppConfig
    @ObservedObject private var timeService = TimeService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDatePicker = false
    @State private var selectedDate = Date()
    @State private var showingClearConfirmation = false
    
    private let logger = Logger(subsystem: "com.scrolldown.app", category: "admin")
    
    var body: some View {
        NavigationStack {
            List {
                // Current Status Section
                Section {
                    if timeService.isSnapshotModeActive {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Snapshot Mode Active", systemImage: "clock.badge.checkmark.fill")
                                .font(.headline)
                                .foregroundColor(.orange)
                            
                            if let display = timeService.snapshotDateDisplay {
                                Text("Testing as: \(display)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Real time: \(Date(), style: .time)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    } else {
                        Label("Using Real Time", systemImage: "clock")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Time Override Status")
                }
                
                // Time Override Controls
                Section {
                    Button {
                        showingDatePicker = true
                    } label: {
                        Label("Set Snapshot Date", systemImage: "calendar.badge.clock")
                    }
                    
                    if timeService.isSnapshotModeActive {
                        Button(role: .destructive) {
                            showingClearConfirmation = true
                        } label: {
                            Label("Clear Override", systemImage: "xmark.circle")
                        }
                    }
                } header: {
                    Text("Controls")
                } footer: {
                    Text("Snapshot mode freezes time to test historical data. Only completed and scheduled games will appear.")
                }
                
                // Preset Dates
                Section {
                    ForEach(presetDates, id: \.date) { preset in
                        Button {
                            applyPreset(preset)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(preset.label)
                                    .font(.body)
                                Text(preset.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Quick Presets")
                }
                
                // Environment Switcher (DEBUG only)
                #if DEBUG
                Section {
                    Picker("Data Source", selection: $appConfig.environment) {
                        ForEach(AppEnvironment.allCases, id: \.self) { env in
                            Text(env.displayName).tag(env)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if appConfig.environment == .localhost {
                        LabeledContent("URL", value: APIConfiguration.localhostURL)
                            .font(.caption)
                        
                        Text("Ensure your local server is running on port \(APIConfiguration.localhostPort)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Data Source")
                } footer: {
                    Text("Localhost connects to your local dev server. Only works in Simulator.")
                }
                #endif
                
                // Environment Info
                Section {
                    LabeledContent("Data Mode", value: appConfig.environment.displayName)
                    if appConfig.environment.usesNetwork {
                        LabeledContent("API URL", value: appConfig.apiBaseURL.absoluteString)
                            .font(.caption)
                    }
                    LabeledContent("App Date", value: AppDate.now().formatted(date: .abbreviated, time: .shortened))
                } header: {
                    Text("Environment")
                }
            }
            .navigationTitle("Admin Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                datePickerSheet
            }
            .alert("Clear Time Override?", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    clearOverride()
                }
            } message: {
                Text("This will return to real system time.")
            }
        }
    }
    
    // MARK: - Date Picker Sheet
    
    private var datePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Select a date and time to freeze the app at that moment.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                DatePicker(
                    "Snapshot Date",
                    selection: $selectedDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Set Snapshot Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingDatePicker = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyOverride(selectedDate)
                        showingDatePicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func applyOverride(_ date: Date) {
        TimeService.shared.setTimeOverride(date)
        logger.info("⏰ Admin: Applied time override to \(date.ISO8601Format())")
    }
    
    private func clearOverride() {
        TimeService.shared.clearTimeOverride()
        logger.info("⏰ Admin: Cleared time override")
    }
    
    private func applyPreset(_ preset: PresetDate) {
        applyOverride(preset.date)
    }
    
    // MARK: - Preset Dates
    
    private struct PresetDate {
        let label: String
        let description: String
        let date: Date
    }
    
    private var presetDates: [PresetDate] {
        let calendar = Calendar.current
        var presets: [PresetDate] = []
        
        // NBA Opening Night 2024-25
        if let date = calendar.date(from: DateComponents(year: 2024, month: 10, day: 23, hour: 4)) {
            presets.append(PresetDate(
                label: "NBA Opening Night 2024",
                description: "Oct 23, 2024 at 4:00 AM",
                date: date
            ))
        }
        
        // Super Bowl Sunday 2024
        if let date = calendar.date(from: DateComponents(year: 2024, month: 2, day: 12, hour: 4)) {
            presets.append(PresetDate(
                label: "Super Bowl LVIII",
                description: "Feb 12, 2024 at 4:00 AM",
                date: date
            ))
        }
        
        // March Madness 2024 Final
        if let date = calendar.date(from: DateComponents(year: 2024, month: 4, day: 9, hour: 4)) {
            presets.append(PresetDate(
                label: "March Madness 2024 Final",
                description: "Apr 9, 2024 at 4:00 AM",
                date: date
            ))
        }
        
        // Yesterday at 4 AM
        if let date = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: Date())),
           let withTime = calendar.date(bySettingHour: 4, minute: 0, second: 0, of: date) {
            presets.append(PresetDate(
                label: "Yesterday at 4:00 AM",
                description: withTime.formatted(date: .abbreviated, time: .shortened),
                date: withTime
            ))
        }
        
        // Last Week
        if let date = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: Date())),
           let withTime = calendar.date(bySettingHour: 4, minute: 0, second: 0, of: date) {
            presets.append(PresetDate(
                label: "One Week Ago",
                description: withTime.formatted(date: .abbreviated, time: .shortened),
                date: withTime
            ))
        }
        
        return presets
    }
}

#Preview {
    AdminSettingsView()
        .environmentObject(AppConfig.shared)
}
