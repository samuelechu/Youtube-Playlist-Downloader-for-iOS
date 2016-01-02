import Foundation

enum MenuAction:String{
    
    case copyLink = "copyLinkAction:"
    case saveVideo = "saveToCameraRollAction:"
    
    //We need this awkward little conversion because «enum»'s can only have literals as raw value types. And «Selector»s aren't literal.
    func selector()->Selector{
        return Selector(self.rawValue)
    }
}