import SwiftUI
import CoreData

/// The grid of floating tiles for the 5–10 most recently accessed matters
/// (§3.2). Hosted inside the desktop `NSPanel`.
struct TileGridView: View {

    @EnvironmentObject private var timerManager: TimerManager

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "lastAccessed", ascending: false)],
        animation: .default
    ) private var matters: FetchedResults<Matter>

    private var recentMatters: [Matter] {
        Array(matters.prefix(10))
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Label("TheWatcher", systemImage: "eye.fill")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 4)

            if recentMatters.isEmpty {
                Text("No recent matters.\nOpen a matter in the main app to begin.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(recentMatters) { matter in
                            MatterTileView(matter: matter)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A single matter tile: client, matter, today's accumulated time and a
/// play/stop toggle.
struct MatterTileView: View {

    @EnvironmentObject private var timerManager: TimerManager
    @ObservedObject var matter: Matter

    private var isRunning: Bool { timerManager.isRunning(matter) }

    private var todaysTotal: Double {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        return matter.timeEntries
            .filter { $0.date >= start }
            .reduce(0) { $0 + $1.duration }
    }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(matter.clientName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(matter.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                if isRunning {
                    Text(Format.clock(timerManager.elapsedSeconds(for: matter)))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.green)
                } else {
                    Text("Today: \(Format.hours(todaysTotal))h")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 4)

            Button {
                timerManager.toggle(matter)
            } label: {
                Image(systemName: isRunning ? "stop.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(isRunning ? .red : .accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isRunning ? Color.green.opacity(0.15) : Color.primary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isRunning ? Color.green.opacity(0.6) : Color.clear, lineWidth: 1.5)
        )
    }
}

/// Transient prompt to capture the narrative for a just-stopped session.
struct NarrativePromptView: View {

    @ObservedObject var entry: TimeEntry
    let onSave: () -> Void

    @State private var text: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What did you work on?")
                .font(.headline)
            Text("\(entry.matter?.clientName ?? "—") · \(entry.matter?.name ?? "—") · \(Format.hours(entry.duration))h")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: $text)
                .font(.body)
                .frame(height: 80)
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.quaternary))

            HStack {
                Button("Skip") { onSave() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    entry.narrative = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    onSave()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 320)
        .onAppear { text = entry.narrative }
    }
}
