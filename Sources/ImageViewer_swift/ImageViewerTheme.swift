import UIKit

public enum ImageViewerTheme {
    case light
    case dark
    
    var tintColor:UIColor {
        switch self {
            case .light:
                return .black
            case .dark:
                return .white
        }
    }
}
