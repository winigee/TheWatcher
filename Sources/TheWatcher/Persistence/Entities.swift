import Foundation
import CoreData

// MARK: - Managed Object Subclasses
//
// The data model is defined entirely in code (see `ManagedObjectModel.swift`)
// so the project builds without an Xcode-edited `.xcdatamodeld` file. Each
// class below corresponds to an entity in the relational schema described in
// the technical specification.

/// The user of the application. Treated as a singleton settings record that
/// holds the default `baseRate` used as the final fallback in rate resolution.
@objc(FeeEarner)
public final class FeeEarner: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var baseRate: Double
}

/// The parent entity for matters. May carry a global override rate that
/// applies to every matter belonging to the client unless overridden lower
/// down the hierarchy.
@objc(Client)
public final class Client: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    /// Stored as an optional number so "no override" is distinguishable from a
    /// deliberately configured rate of 0.
    @NSManaged public var overrideRate: NSNumber?
    @NSManaged public var matters: Set<Matter>
}

/// A specific case or project belonging to a client.
@objc(Matter)
public final class Matter: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var overrideRate: NSNumber?
    @NSManaged public var lastAccessed: Date
    @NSManaged public var client: Client?
    @NSManaged public var timeEntries: Set<TimeEntry>
}

/// The transactional time record. `appliedRate` is resolved and frozen at the
/// moment the entry is created so historical reporting stays stable even if
/// client or matter rates change later.
@objc(TimeEntry)
public final class TimeEntry: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    /// Duration in decimal hours (e.g. 1.5 == one hour thirty minutes).
    @NSManaged public var duration: Double
    @NSManaged public var narrative: String
    @NSManaged public var appliedRate: Double
    @NSManaged public var matter: Matter?
}

// MARK: - Convenience Accessors

public extension Client {
    /// Optional override expressed as a plain `Double?` for ergonomic use in
    /// SwiftUI and the rate resolver.
    var overrideRateValue: Double? {
        get { overrideRate?.doubleValue }
        set { overrideRate = newValue.map(NSNumber.init(value:)) }
    }

    var sortedMatters: [Matter] {
        matters.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

public extension Matter {
    var overrideRateValue: Double? {
        get { overrideRate?.doubleValue }
        set { overrideRate = newValue.map(NSNumber.init(value:)) }
    }

    var clientName: String { client?.name ?? "—" }
}

public extension TimeEntry {
    /// The monetary value of the entry: decimal hours multiplied by the frozen
    /// applied rate.
    var totalValue: Double { duration * appliedRate }
}
