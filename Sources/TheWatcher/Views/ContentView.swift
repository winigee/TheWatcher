import SwiftUI

/// The administrative hub. A sidebar switches between the three primary views
/// described in §3.1.
struct ContentView: View {

    enum Section: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case clients = "Clients & Matters"
        case export = "Export"

        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .dashboard: return "list.bullet.rectangle"
            case .clients: return "folder"
            case .export: return "square.and.arrow.up"
            }
        }
    }

    @State private var selection: Section? = .dashboard

    var body: some View {
        NavigationSplitView {
            List(Section.allCases, selection: $selection) { section in
                Label(section.rawValue, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
            .listStyle(.sidebar)
        } detail: {
            switch selection ?? .dashboard {
            case .dashboard: DashboardView()
            case .clients: ClientMatterView()
            case .export: ExportView()
            }
        }
        .navigationTitle("TheWatcher")
    }
}
