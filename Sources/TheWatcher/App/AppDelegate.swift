import AppKit
import Combine

/// Hosts the desktop tile system and bridges AppKit lifecycle into the SwiftUI
/// world. Kept lightweight: it just wires the tile manager to shared state once
/// the SwiftUI scene is ready.
final class AppDelegate: NSObject, NSApplicationDelegate {

    private(set) var tileManager: DesktopTileManager?
    private var cancellables = Set<AnyCancellable>()

    func configure(timerManager: TimerManager, persistence: PersistenceController) {
        guard tileManager == nil else { return }
        let manager = DesktopTileManager(timerManager: timerManager, persistence: persistence)
        tileManager = manager
        manager.show()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running so the floating tiles remain available even when the main
        // administrative window is closed.
        false
    }
}
