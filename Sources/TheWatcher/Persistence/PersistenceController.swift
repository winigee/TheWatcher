import Foundation
import CoreData

/// Owns the Core Data stack. The SQLite store lives in the user's Application
/// Support directory (the default location for `NSPersistentContainer`), so no
/// backend server or cloud sync is involved — the app is fully standalone.
public final class PersistenceController {

    public static let shared = PersistenceController()

    public let container: NSPersistentContainer

    public var viewContext: NSManagedObjectContext { container.viewContext }

    /// - Parameter inMemory: When `true` the store is created in `/dev/null`,
    ///   used for previews and unit tests so nothing touches the real database.
    public init(inMemory: Bool = false) {
        container = NSPersistentContainer(
            name: "TheWatcher",
            managedObjectModel: ManagedObjectModel.make()
        )

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error {
                // A failure here means the on-disk store is unusable; surface it
                // loudly during development rather than failing silently.
                fatalError("Unable to load persistent store: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    /// Saves the view context if it has outstanding changes.
    @discardableResult
    public func save() -> Bool {
        guard viewContext.hasChanges else { return true }
        do {
            try viewContext.save()
            return true
        } catch {
            assertionFailure("Failed to save context: \(error)")
            return false
        }
    }

    // MARK: - Fee Earner (singleton)

    /// Returns the single Fee Earner record, creating a default one on first
    /// launch. The Fee Earner's `baseRate` is the ultimate fallback rate.
    @discardableResult
    public func currentFeeEarner() -> FeeEarner {
        let request = NSFetchRequest<FeeEarner>(entityName: "FeeEarner")
        request.fetchLimit = 1
        if let existing = try? viewContext.fetch(request).first {
            return existing
        }
        let fe = FeeEarner(context: viewContext)
        fe.id = UUID()
        fe.name = "Fee Earner"
        fe.baseRate = 250
        save()
        return fe
    }
}
