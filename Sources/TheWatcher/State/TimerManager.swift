import Foundation
import CoreData
import Combine

/// Central application state and timekeeping engine.
///
/// Enforces the **Mutual Exclusion Protocol** (§3.2): at most one matter timer
/// may run at a time. Starting a timer on one matter automatically stops any
/// timer already running on another.
@MainActor
public final class TimerManager: ObservableObject {

    /// A timer that is currently counting against a matter.
    public struct ActiveSession: Equatable {
        public let matterID: NSManagedObjectID
        public let startedAt: Date
    }

    @Published public private(set) var activeSession: ActiveSession?
    /// Drives live UI updates (the running tile's elapsed display).
    @Published public private(set) var tick: Date = Date()

    /// Emitted when a session is stopped, so the UI can present the narrative
    /// prompt for the just-created entry.
    public let didStopSession = PassthroughSubject<NSManagedObjectID, Never>()

    private let persistence: PersistenceController
    private var ticker: AnyCancellable?

    public init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    private var context: NSManagedObjectContext { persistence.viewContext }

    // MARK: - Public API

    public func isRunning(_ matter: Matter) -> Bool {
        activeSession?.matterID == matter.objectID
    }

    /// Elapsed seconds for the currently running matter (0 if not running).
    public func elapsedSeconds(for matter: Matter) -> TimeInterval {
        guard let session = activeSession, session.matterID == matter.objectID else { return 0 }
        return tick.timeIntervalSince(session.startedAt)
    }

    /// Toggles the timer for a matter, honouring mutual exclusion.
    public func toggle(_ matter: Matter) {
        if isRunning(matter) {
            stop()
        } else {
            start(matter)
        }
    }

    /// Starts timing `matter`, first stopping any other running session.
    public func start(_ matter: Matter) {
        // Mutual exclusion: pause whatever is currently running first.
        if activeSession != nil {
            stop()
        }

        matter.lastAccessed = Date()
        persistence.save()

        activeSession = ActiveSession(matterID: matter.objectID, startedAt: Date())
        startTicker()
    }

    /// Stops the active session, persisting it as a time entry with the rate
    /// resolved and frozen at this moment.
    @discardableResult
    public func stop() -> NSManagedObjectID? {
        guard let session = activeSession else { return nil }
        stopTicker()
        activeSession = nil

        guard let matter = try? context.existingObject(with: session.matterID) as? Matter else {
            return nil
        }

        let elapsedHours = Date().timeIntervalSince(session.startedAt) / 3600.0
        let resolution = RateResolver.resolve(
            for: matter,
            feeEarner: persistence.currentFeeEarner()
        )

        let entry = TimeEntry(context: context)
        entry.id = UUID()
        entry.date = Date()
        entry.duration = roundedToBillingIncrement(elapsedHours)
        entry.narrative = ""               // Completed later via the popover.
        entry.appliedRate = resolution.rate
        entry.matter = matter

        persistence.save()
        didStopSession.send(entry.objectID)
        return entry.objectID
    }

    // MARK: - Ticker

    private func startTicker() {
        tick = Date()
        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in self?.tick = now }
    }

    private func stopTicker() {
        ticker?.cancel()
        ticker = nil
    }

    // MARK: - Helpers

    /// Rounds durations up to the conventional six-minute (0.1h) billing
    /// increment used in legal timekeeping, with a one-unit minimum.
    private func roundedToBillingIncrement(_ hours: Double) -> Double {
        let unit = 0.1
        let units = max(1, (hours / unit).rounded(.up))
        return (units * unit * 10).rounded() / 10
    }
}
