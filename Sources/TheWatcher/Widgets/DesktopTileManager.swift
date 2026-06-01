import AppKit
import SwiftUI
import CoreData
import Combine

/// Manages the grid of floating desktop tiles.
///
/// Tiles are implemented as non-activating `NSPanel` instances layered on the
/// desktop (§1). This sidesteps WidgetKit's refresh limitations and gives the
/// instant, reliable state changes the spec calls for. A single panel hosts the
/// SwiftUI tile grid so the tiles move and refresh as one cohesive surface.
@MainActor
final class DesktopTileManager {

    private let timerManager: TimerManager
    private let persistence: PersistenceController
    private var panel: NSPanel?
    private var cancellables = Set<AnyCancellable>()

    init(timerManager: TimerManager, persistence: PersistenceController) {
        self.timerManager = timerManager
        self.persistence = persistence

        // When a session stops, surface the narrative prompt for that entry.
        timerManager.didStopSession
            .receive(on: RunLoop.main)
            .sink { [weak self] entryID in
                self?.promptForNarrative(entryID: entryID)
            }
            .store(in: &cancellables)
    }

    // MARK: - Panel lifecycle

    func show() {
        if panel == nil { panel = makePanel() }
        positionPanel()
        panel?.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 520),
            styleMask: [.nonactivatingPanel, .titled, .closable, .utilityWindow, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "TheWatcher"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true

        let root = TileGridView()
            .environment(\.managedObjectContext, persistence.viewContext)
            .environmentObject(timerManager)

        let hosting = NSHostingView(rootView: root)
        hosting.autoresizingMask = [.width, .height]
        panel.contentView = hosting
        return panel
    }

    private func positionPanel() {
        guard let panel, let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = panel.frame.size
        // Dock to the top-right of the active screen.
        let origin = NSPoint(
            x: visible.maxX - size.width - 24,
            y: visible.maxY - size.height - 24
        )
        panel.setFrameOrigin(origin)
    }

    // MARK: - Narrative prompt

    /// Presents a transient popover-style prompt anchored to the tile panel so
    /// the fee earner can describe the session that just ended (§3.2). Ignoring
    /// it leaves the narrative blank for later completion in the main app.
    private func promptForNarrative(entryID: NSManagedObjectID) {
        guard let panel,
              let entry = try? persistence.viewContext.existingObject(with: entryID) as? TimeEntry
        else { return }

        let promptPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        promptPanel.title = "Session Narrative"
        promptPanel.isFloatingPanel = true
        promptPanel.level = .floating

        let view = NarrativePromptView(entry: entry) { [weak promptPanel] in
            self.persistence.save()
            promptPanel?.close()
        }
        .environment(\.managedObjectContext, persistence.viewContext)

        promptPanel.contentView = NSHostingView(rootView: view)

        // Anchor just left of the tile panel.
        let anchor = panel.frame
        promptPanel.setFrameOrigin(NSPoint(x: anchor.minX - 332, y: anchor.maxY - 200))
        promptPanel.orderFrontRegardless()
    }
}
