import Foundation
import CoreData

public class Song: NSManagedObject {

    @nonobjc public class func theFetchRequest() -> NSFetchRequest<Song> {
        return NSFetchRequest<Song>(entityName: "Song")
    }
    
    @NSManaged public var duration: NSNumber?
    @NSManaged public var durationStr: String?
    @NSManaged public var expireDate: NSDate?
    @NSManaged public var identifier: String?
    @NSManaged public var isDownloaded: NSNumber?
    @NSManaged public var quality: NSNumber?
    @NSManaged public var streamURL: String?
    @NSManaged public var thumbnail: Data?
    @NSManaged public var title: String?
    @NSManaged public var playlists: NSSet?
    
}

extension Song {
    
    @objc(addPlaylistsObject:)
    @NSManaged public func addToPlaylists(_ value: Playlist)
    
    @objc(removePlaylistsObject:)
    @NSManaged public func removeFromPlaylists(_ value: Playlist)

}
