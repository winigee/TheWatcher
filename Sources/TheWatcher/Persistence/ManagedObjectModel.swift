import Foundation
import CoreData

/// Builds the Core Data `NSManagedObjectModel` programmatically. Defining the
/// schema in code keeps the relational design (and its inverse relationships)
/// reviewable in source control and removes the dependency on Xcode's visual
/// model editor.
enum ManagedObjectModel {

    static func make() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // MARK: Entities
        let feeEarner = NSEntityDescription()
        feeEarner.name = "FeeEarner"
        feeEarner.managedObjectClassName = NSStringFromClass(FeeEarner.self)

        let client = NSEntityDescription()
        client.name = "Client"
        client.managedObjectClassName = NSStringFromClass(Client.self)

        let matter = NSEntityDescription()
        matter.name = "Matter"
        matter.managedObjectClassName = NSStringFromClass(Matter.self)

        let timeEntry = NSEntityDescription()
        timeEntry.name = "TimeEntry"
        timeEntry.managedObjectClassName = NSStringFromClass(TimeEntry.self)

        // MARK: FeeEarner attributes
        feeEarner.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("name", .stringAttributeType, defaultValue: ""),
            attribute("baseRate", .doubleAttributeType, defaultValue: 0.0)
        ]

        // MARK: Client attributes
        let clientOverride = attribute("overrideRate", .doubleAttributeType, optional: true)
        client.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("name", .stringAttributeType, defaultValue: ""),
            clientOverride
        ]

        // MARK: Matter attributes
        let matterOverride = attribute("overrideRate", .doubleAttributeType, optional: true)
        matter.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("name", .stringAttributeType, defaultValue: ""),
            matterOverride,
            attribute("lastAccessed", .dateAttributeType, defaultValue: Date(timeIntervalSinceReferenceDate: 0))
        ]

        // MARK: TimeEntry attributes
        timeEntry.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("date", .dateAttributeType),
            attribute("duration", .doubleAttributeType, defaultValue: 0.0),
            attribute("narrative", .stringAttributeType, defaultValue: ""),
            attribute("appliedRate", .doubleAttributeType, defaultValue: 0.0)
        ]

        // MARK: Relationships
        // Client <->> Matter
        let clientToMatters = NSRelationshipDescription()
        clientToMatters.name = "matters"
        clientToMatters.destinationEntity = matter
        clientToMatters.minCount = 0
        clientToMatters.maxCount = 0 // to-many
        clientToMatters.deleteRule = .cascadeDeleteRule
        clientToMatters.isOptional = true

        let matterToClient = NSRelationshipDescription()
        matterToClient.name = "client"
        matterToClient.destinationEntity = client
        matterToClient.minCount = 0
        matterToClient.maxCount = 1 // to-one
        matterToClient.deleteRule = .nullifyDeleteRule
        matterToClient.isOptional = true

        clientToMatters.inverseRelationship = matterToClient
        matterToClient.inverseRelationship = clientToMatters

        // Matter <->> TimeEntry
        let matterToEntries = NSRelationshipDescription()
        matterToEntries.name = "timeEntries"
        matterToEntries.destinationEntity = timeEntry
        matterToEntries.minCount = 0
        matterToEntries.maxCount = 0 // to-many
        matterToEntries.deleteRule = .cascadeDeleteRule
        matterToEntries.isOptional = true

        let entryToMatter = NSRelationshipDescription()
        entryToMatter.name = "matter"
        entryToMatter.destinationEntity = matter
        entryToMatter.minCount = 0
        entryToMatter.maxCount = 1 // to-one
        entryToMatter.deleteRule = .nullifyDeleteRule
        entryToMatter.isOptional = true

        matterToEntries.inverseRelationship = entryToMatter
        entryToMatter.inverseRelationship = matterToEntries

        client.properties.append(clientToMatters)
        matter.properties.append(contentsOf: [matterToClient, matterToEntries])
        timeEntry.properties.append(entryToMatter)

        model.entities = [feeEarner, client, matter, timeEntry]
        return model
    }

    // MARK: - Helpers

    private static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        optional: Bool = false,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let attr = NSAttributeDescription()
        attr.name = name
        attr.attributeType = type
        attr.isOptional = optional
        if let defaultValue { attr.defaultValue = defaultValue }
        return attr
    }
}
