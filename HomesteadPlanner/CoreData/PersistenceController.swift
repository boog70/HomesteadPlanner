import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "HomesteadPlanner")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data failed to load: \(error)")
            }
        }
    }

    var viewContext: NSManagedObjectContext { container.viewContext }

    func save() {
        let context = viewContext
        if context.hasChanges {
            try? context.save()
        }
    }
}
