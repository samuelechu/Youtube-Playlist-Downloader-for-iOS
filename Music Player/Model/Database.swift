import Foundation
import CoreData

private let sharedURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Music_Player.sqlite")

class Database {
    
    static var shared = Database(url: sharedURL)
    
    private let coordinator: NSPersistentStoreCoordinator
    private(set) var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    let settings: Settings
    
    init(url: URL) {
        let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Music_Player", withExtension: "momd")!)!
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try! coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        managedObjectContext.persistentStoreCoordinator = coordinator
        
        if let settings = try! managedObjectContext.fetch(Settings.theFetchRequest()).first {
            self.settings = settings
        } else {
            settings = NSEntityDescription.insertNewObject(forEntityName: "Settings", into: managedObjectContext) as! Settings
            settings.quality = 0 //todo enums
            settings.cache = 0
            settings.playlist = "https://www.youtube.com/playlist?list=PLyD2IQPajS7Z3VcvQmqJWPOQtXQ1qnDha"
        }
    }
    
    func save() {
        try! self.managedObjectContext.save()
    }
    
    func playlists(sorted: Bool) -> [Playlist] {
        let request = Playlist.theFetchRequest()
        if sorted {
            request.sortDescriptors = [NSSortDescriptor(key: "playlistName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))]
        }
        return try! managedObjectContext.fetch(request)
    }
    
    func findPlaylist(named name: String) -> Playlist? {
        let request = Playlist.theFetchRequest()
        request.predicate = NSPredicate(format: "playlistName = %@", name)
        request.fetchLimit = 1
        return try! managedObjectContext.fetch(request).first
    }
    
    @discardableResult func createPlaylist(named name: String) -> Playlist {
        let playlist = NSEntityDescription.insertNewObject(forEntityName: "Playlist", into: managedObjectContext) as! Playlist
        playlist.playlistName = name
        return playlist
    }
    
    func delete(_ object: NSManagedObject) {
        managedObjectContext.delete(object)
    }
    
}
