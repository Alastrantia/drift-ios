import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("fadeIn") private var fadeIn = true
    @AppStorage("mixWithOthers") private var mixWithOthers = true
    @AppStorage("haptics") private var haptics = true
    @AppStorage("bedtime") private var bedtimeReminder = false
    @AppStorage("goal") private var goal = 60
    @State private var bedtime = Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: .now) ?? .now

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        SoundscapeArtwork(scape: .featured, cornerRadius: 30, symbolSize: 24)
                            .frame(width: 60, height: 60)
                            .clipShape(.circle)
                        VStack(alignment: .leading) {
                            Text("Night owl").font(.headline)
                            Text("12-day streak · 448 min this week").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Playback") {
                    Toggle("Gentle fade-in", systemImage: "waveform.path.ecg", isOn: $fadeIn)
                    Toggle("Mix with other audio", systemImage: "speaker.wave.2", isOn: $mixWithOthers)
                    Stepper("Nightly goal: \(goal) min", value: $goal, in: 15...180, step: 15)
                }

                Section("Bedtime") {
                    Toggle("Bedtime reminder", systemImage: "bell.badge", isOn: $bedtimeReminder.animation(.smooth))
                    if bedtimeReminder {
                        DatePicker("Remind me at", selection: $bedtime, displayedComponents: .hourAndMinute)
                    }
                }

                Section {
                    Toggle("Haptics", systemImage: "iphone.radiowaves.left.and.right", isOn: $haptics)
                } footer: {
                    Text("Drift generates every sound on-device. Nothing is streamed, recorded or tracked.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
    }
}
