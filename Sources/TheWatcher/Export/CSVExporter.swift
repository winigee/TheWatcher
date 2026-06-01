import Foundation
import CoreData

/// Produces the CSV timesheet described in §4. The relational data is flattened
/// to one row per time entry, ordered chronologically.
public enum CSVExporter {

    public static let columns = [
        "Date", "Client", "Matter", "Narrative", "Duration", "Rate", "Total Value"
    ]

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "dd/MM/yyyy"   // DD/MM/YYYY per spec.
        return f
    }()

    /// Fetches entries between `start` and `end` (inclusive) and renders them
    /// as a CSV string.
    public static func export(
        from start: Date,
        to end: Date,
        context: NSManagedObjectContext
    ) -> String {
        let calendar = Calendar.current
        let lowerBound = calendar.startOfDay(for: start)
        // Make the end date inclusive of the whole day.
        let upperBound = calendar.startOfDay(for: end).addingTimeInterval(24 * 3600)

        let request = NSFetchRequest<TimeEntry>(entityName: "TimeEntry")
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            lowerBound as NSDate, upperBound as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        let entries = (try? context.fetch(request)) ?? []
        return render(entries: entries)
    }

    /// Renders a set of entries to CSV. Exposed separately so it can be unit
    /// tested without a Core Data fetch.
    public static func render(entries: [TimeEntry]) -> String {
        var rows = [columns.map(escape).joined(separator: ",")]

        for entry in entries {
            let row = [
                dateFormatter.string(from: entry.date),
                entry.matter?.clientName ?? "—",
                entry.matter?.name ?? "—",
                entry.narrative,
                formatDecimal(entry.duration),
                formatDecimal(entry.appliedRate),
                formatDecimal(entry.totalValue)
            ]
            rows.append(row.map(escape).joined(separator: ","))
        }

        return rows.joined(separator: "\r\n")
    }

    // MARK: - Formatting

    private static func formatDecimal(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    /// Quotes a field if it contains characters significant to CSV, escaping
    /// embedded quotes by doubling them (RFC 4180).
    private static func escape(_ field: String) -> String {
        guard field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") else {
            return field
        }
        let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
