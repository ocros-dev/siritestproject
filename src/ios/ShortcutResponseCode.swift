enum ShortcutResponseCode: String{
    case created = "1"
    case modified = "2"
    case deleted = "3"
    case dismiss = "4"
    case internalError = "5"
    case noIos12 = "6"
    case noPersistentIdentifier = "7"
    
    var description: String {
        switch self {
            case .created:
                return "Siri shortcut created."
            case .modified:
                return "Siri shortcut modified."
            case .deleted:
                return "Siri shortcut deleted."
            case .dismiss:
                return "Siri shortcut dismissed."
            case .internalError:
                return "Internal error occured."
            case .noIos12:
                return "Error while performing shortcut operation, user might not run iOS 12."
            case .noPersistentIdentifier:
                return "Error while performing shortcut operation, no persistent identifier sent."
        }
    }
}