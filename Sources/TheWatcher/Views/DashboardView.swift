import SwiftUI
import CoreData

/// Chronological list of today's time entries with inline editing of the
/// narrative, duration and applied rate (§3.1).
struct DashboardView: View {

    @Environment(\.managedObjectContext) private var context

    @FetchRequest private var entries: FetchedResults<TimeEntry>

    init() {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = start.addingTimeInterval(24 * 3600)
        _entries = FetchRequest(
            sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)],
            predicate: NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate),
            animation: .default
        )
    }

    private var dayTotalValue: Double {
        entries.reduce(0) { $0 + $1.totalValue }
    }

    private var dayTotalHours: Double {
        entries.reduce(0) { $0 + $1.duration }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if entries.isEmpty {
                ContentUnavailablePlaceholder(
                    title: "No time recorded today",
                    message: "Start a timer from a desktop tile to log your first entry.",
                    systemImage: "clock.badge.questionmark"
                )
            } else {
                Table(entries) {
                    TableColumn("Time") { entry in
                        Text(entry.date, format: .dateTime.hour().minute())
                            .foregroundStyle(.secondary)
                    }
                    .width(60)

                    TableColumn("Client / Matter") { entry in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(entry.matter?.clientName ?? "—")
                                .font(.caption).foregroundStyle(.secondary)
                            Text(entry.matter?.name ?? "—")
                        }
                    }

                    TableColumn("Narrative") { entry in
                        TextField("Add narrative…", text: bindingNarrative(entry), axis: .vertical)
                            .textFieldStyle(.plain)
                    }

                    TableColumn("Duration (h)") { entry in
                        TextField("0.0", value: bindingDuration(entry), format: .number)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                    }
                    .width(90)

                    TableColumn("Rate") { entry in
                        TextField("0", value: bindingRate(entry), format: .number)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    .width(100)

                    TableColumn("Value") { entry in
                        Text(Format.money(entry.totalValue))
                            .monospacedDigit()
                    }
                    .width(90)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Today")
                    .font(.largeTitle.bold())
                Text(Date(), format: .dateTime.weekday(.wide).day().month(.wide).year())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(Format.hours(dayTotalHours)) h")
                    .font(.title2.monospacedDigit())
                Text(Format.money(dayTotalValue))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    // MARK: - Inline edit bindings

    private func bindingNarrative(_ entry: TimeEntry) -> Binding<String> {
        Binding(
            get: { entry.narrative },
            set: { entry.narrative = $0; save() }
        )
    }

    private func bindingDuration(_ entry: TimeEntry) -> Binding<Double> {
        Binding(
            get: { entry.duration },
            set: { entry.duration = max(0, $0); save() }
        )
    }

    private func bindingRate(_ entry: TimeEntry) -> Binding<Double> {
        Binding(
            get: { entry.appliedRate },
            set: { entry.appliedRate = max(0, $0); save() }
        )
    }

    private func save() {
        try? context.save()
    }
}

/// Lightweight placeholder usable on macOS 13 where `ContentUnavailableView`
/// is not yet available.
struct ContentUnavailablePlaceholder: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
