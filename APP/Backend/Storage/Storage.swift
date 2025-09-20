import CoreData
import os.log

final class Storage: ObservableObject, @unchecked Sendable {
	static let shared = Storage()
	let container: NSPersistentContainer
	
	private let _name: String = "Feather"
	private let saveQueue = DispatchQueue(label: "com.feather.storage.save", qos: .userInitiated)
	private let logger = Logger(subsystem: "com.feather.storage", category: "Storage")
	
	init(inMemory: Bool = false) {
		container = NSPersistentContainer(name: _name)
		
		if inMemory {
			container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
		}
		
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error as NSError? {
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})
		
		container.viewContext.automaticallyMergesChangesFromParent = true
	}
	
	var context: NSManagedObjectContext {
		container.viewContext
	}
	
	func saveContext() {
		DispatchQueue.main.async {
			if self.context.hasChanges {
				try? self.context.save()
			}
		}
	}
	
	@MainActor
	func clearContext<T: NSManagedObject>(request: NSFetchRequest<T>) {
		do {
			let deleteRequest = NSBatchDeleteRequest(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult>)
			try context.execute(deleteRequest)
			logger.info("Successfully cleared context for \(T.self)")
		} catch {
			logger.error("Failed to clear context for \(T.self): \(error.localizedDescription)")
		}
	}
	
	@MainActor
	func countContent<T: NSManagedObject>(for type: T.Type) -> String {
		let request = T.fetchRequest()
		do {
			let count = try context.count(for: request)
			return "\(count)"
		} catch {
			logger.error("Failed to count content for \(type): \(error.localizedDescription)")
			return "0"
		}
	}
}
