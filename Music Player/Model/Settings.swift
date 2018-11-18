import Foundation
import CoreData


//todo replace Settings(*) entity with Config(name, value) entity – this would be easier to manage
//or store settings in the UserDefaults instead
public class Settings: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Settings> {
        return NSFetchRequest<Settings>(entityName: "Settings")
    }
    
    @NSManaged public var cache: NSNumber?
    @NSManaged public var playlist: String?
    @NSManaged public var quality: NSNumber?
    
}
