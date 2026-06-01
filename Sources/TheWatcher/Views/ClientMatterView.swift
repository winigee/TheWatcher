import SwiftUI
import CoreData

/// CRUD interface for clients and matters, including level-specific rate
/// overrides (§3.1). Also exposes the Fee Earner's default base rate, which is
/// the final fallback in resolution.
struct ClientMatterView: View {

    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
        animation: .default
    ) private var clients: FetchedResults<Client>

    @State private var selectedClientID: NSManagedObjectID?

    private var selectedClient: Client? {
        guard let id = selectedClientID else { return nil }
        return try? context.existingObject(with: id) as? Client
    }

    var body: some View {
        HSplitView {
            clientList
                .frame(minWidth: 240)
            matterDetail
                .frame(minWidth: 360)
        }
        .navigationTitle("Clients & Matters")
        .toolbar {
            ToolbarItem {
                FeeEarnerRateButton()
            }
        }
    }

    // MARK: - Client list

    private var clientList: some View {
        VStack(spacing: 0) {
            List(selection: $selectedClientID) {
                ForEach(clients) { client in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(client.name)
                        if let rate = client.overrideRateValue {
                            Text("Client rate \(Format.money(rate))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .tag(client.objectID)
                }
                .onDelete(perform: deleteClients)
            }

            Divider()
            HStack {
                Button(action: addClient) {
                    Label("Add Client", systemImage: "plus")
                }
                Spacer()
            }
            .padding(8)
        }
    }

    // MARK: - Matter detail

    @ViewBuilder
    private var matterDetail: some View {
        if let client = selectedClient {
            ClientDetailView(client: client)
                .id(client.objectID)
        } else {
            ContentUnavailablePlaceholder(
                title: "Select a client",
                message: "Choose a client on the left to manage its matters and rates.",
                systemImage: "folder"
            )
        }
    }

    // MARK: - Actions

    private func addClient() {
        let client = Client(context: context)
        client.id = UUID()
        client.name = "New Client"
        save()
        selectedClientID = client.objectID
    }

    private func deleteClients(at offsets: IndexSet) {
        for index in offsets {
            context.delete(clients[index])
        }
        save()
    }

    private func save() { try? context.save() }
}

/// Editor for a single client and its matters.
struct ClientDetailView: View {

    @Environment(\.managedObjectContext) private var context
    @ObservedObject var client: Client

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Client fields
                GroupBox("Client") {
                    VStack(alignment: .leading, spacing: 12) {
                        LabeledContent("Name") {
                            TextField("Client name", text: Binding(
                                get: { client.name },
                                set: { client.name = $0; save() }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                        OptionalRateField(
                            label: "Client rate override",
                            value: Binding(
                                get: { client.overrideRateValue },
                                set: { client.overrideRateValue = $0; save() }
                            )
                        )
                    }
                    .padding(8)
                }

                // Matters
                GroupBox("Matters") {
                    VStack(alignment: .leading, spacing: 8) {
                        if client.sortedMatters.isEmpty {
                            Text("No matters yet.")
                                .font(.caption).foregroundStyle(.secondary)
                                .padding(.vertical, 4)
                        }
                        ForEach(client.sortedMatters) { matter in
                            MatterRow(matter: matter)
                            Divider()
                        }
                        Button(action: addMatter) {
                            Label("Open Matter", systemImage: "plus")
                        }
                        .padding(.top, 4)
                    }
                    .padding(8)
                }
            }
            .padding()
        }
    }

    private func addMatter() {
        let matter = Matter(context: context)
        matter.id = UUID()
        matter.name = "New Matter"
        matter.lastAccessed = Date()
        matter.client = client
        save()
    }

    private func save() { try? context.save() }
}

/// A single editable matter row with its own override and a delete control.
struct MatterRow: View {

    @Environment(\.managedObjectContext) private var context
    @ObservedObject var matter: Matter

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Matter name", text: Binding(
                    get: { matter.name },
                    set: { matter.name = $0; save() }
                ))
                .textFieldStyle(.roundedBorder)

                OptionalRateField(
                    label: "Matter rate override",
                    value: Binding(
                        get: { matter.overrideRateValue },
                        set: { matter.overrideRateValue = $0; save() }
                    )
                )
            }

            Button(role: .destructive) {
                context.delete(matter)
                save()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }

    private func save() { try? context.save() }
}

/// A rate field that can be empty (no override) or hold a value. A toggle
/// distinguishes "inherit" from an explicit rate so 0 remains meaningful.
struct OptionalRateField: View {
    let label: String
    @Binding var value: Double?

    var body: some View {
        HStack {
            Toggle(isOn: Binding(
                get: { value != nil },
                set: { enabled in value = enabled ? (value ?? 0) : nil }
            )) {
                Text(label)
            }
            .toggleStyle(.checkbox)

            Spacer()

            if value != nil {
                TextField("Rate", value: Binding(
                    get: { value ?? 0 },
                    set: { value = $0 }
                ), format: .number)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
            } else {
                Text("Inherited")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

/// Toolbar control for editing the Fee Earner's default base rate.
struct FeeEarnerRateButton: View {
    @Environment(\.managedObjectContext) private var context
    @State private var showing = false

    var body: some View {
        Button {
            showing.toggle()
        } label: {
            Label("Default Rate", systemImage: "person.crop.circle")
        }
        .popover(isPresented: $showing) {
            let fe = PersistenceController.shared.currentFeeEarner()
            VStack(alignment: .leading, spacing: 12) {
                Text("Fee Earner").font(.headline)
                LabeledContent("Name") {
                    TextField("Name", text: Binding(
                        get: { fe.name }, set: { fe.name = $0; try? context.save() }
                    ))
                    .frame(width: 160)
                }
                LabeledContent("Default base rate") {
                    TextField("Rate", value: Binding(
                        get: { fe.baseRate }, set: { fe.baseRate = $0; try? context.save() }
                    ), format: .number)
                    .frame(width: 100)
                }
                Text("Used when no client, matter or entry override applies.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding()
            .frame(width: 280)
        }
    }
}
