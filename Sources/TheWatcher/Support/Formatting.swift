import Foundation

/// Shared formatting helpers used across the UI.
enum Format {

    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "en_GB")
        return f
    }()

    static func money(_ value: Double) -> String {
        currency.string(from: NSNumber(value: value)) ?? String(format: "£%.2f", value)
    }

    /// Decimal hours, e.g. 1.5.
    static func hours(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    /// Elapsed seconds rendered as H:MM:SS for the live running display.
    static func clock(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%d:%02d:%02d", h, m, s)
    }
}
