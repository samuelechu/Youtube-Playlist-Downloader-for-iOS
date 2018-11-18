import Foundation
import CoreData

private let sharedURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Music_Player.sqlite")

class Database {
    
    static var shared = Database(url: sharedURL)
    
    private let coordinator: NSPersistentStoreCoordinator
    private(set) var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    
    init(url: URL) {
        let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Music_Player", withExtension: "momd")!)!
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try! coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        managedObjectContext.persistentStoreCoordinator = coordinator
    }
    
    func save() {
        try! self.managedObjectContext.save()
    }
    
}
