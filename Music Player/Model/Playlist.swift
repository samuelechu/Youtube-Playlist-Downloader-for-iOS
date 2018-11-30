import Foundation
import CoreData

public class Playlist: NSManagedObject {

    @nonobjc public class func theFetchRequest() -> NSFetchRequest<Playlist> {
        return NSFetchRequest<Playlist>(entityName: "Playlist")
    }
    
    @NSManaged public var playlistName: String?
    @NSManaged public var songs: NSSet?
    
}
