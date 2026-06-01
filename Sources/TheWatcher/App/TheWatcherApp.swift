import SwiftUI

/// Application entry point. The main window is the administrative hub; the
/// floating desktop tiles are managed separately by `DesktopTileManager` via
/// the app delegate.
@main
struct TheWatcherApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let persistence = PersistenceController.shared
    @StateObject private var timerManager = TimerManager(persistence: PersistenceController.shared)

    var body: some Scene {
        WindowGroup("TheWatcher") {
            ContentView()
                .environment(\.managedObjectContext, persistence.viewContext)
                .environmentObject(timerManager)
                .frame(minWidth: 900, minHeight: 560)
                .onAppear {
                    appDelegate.configure(
                        timerManager: timerManager,
                        persistence: persistence
                    )
                }
        }
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(after: .windowArrangement) {
                Button("Show Desktop Tiles") {
                    appDelegate.tileManager?.show()
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])

                Button("Hide Desktop Tiles") {
                    appDelegate.tileManager?.hide()
                }
            }
        }
    }
}
