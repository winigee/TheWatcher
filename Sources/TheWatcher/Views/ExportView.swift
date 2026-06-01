import SwiftUI
import UniformTypeIdentifiers

/// Reporting interface that generates a CSV timesheet between two dates (§3.1,
/// §4).
struct ExportView: View {

    @Environment(\.managedObjectContext) private var context

    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var statusMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Export Timesheet")
                .font(.largeTitle.bold())

            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End date", selection: $endDate, displayedComponents: .date)

                    HStack {
                        Button {
                            export()
                        } label: {
                            Label("Export CSV…", systemImage: "square.and.arrow.up")
                        }
                        .keyboardShortcut("e", modifiers: .command)
                        .disabled(endDate < startDate)

                        if let statusMessage {
                            Text(statusMessage)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(8)
            }

            Text("Generates one row per time entry with columns: \(CSVExporter.columns.joined(separator: ", ")).")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .navigationTitle("Export")
    }

    private func export() {
        let csv = CSVExporter.export(from: startDate, to: endDate, context: context)

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = defaultFilename()
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            statusMessage = "Saved to \(url.lastPathComponent)"
        } catch {
            statusMessage = "Export failed: \(error.localizedDescription)"
        }
    }

    private func defaultFilename() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        return "TheWatcher_\(f.string(from: startDate))-\(f.string(from: endDate)).csv"
    }
}
