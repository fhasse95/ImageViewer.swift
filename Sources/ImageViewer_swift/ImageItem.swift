import UIKit

public enum ImageItem {
    case image(UIImage, UIImage)
    #if canImport(SDWebImage)
    case url(URL, placeholder: UIImage?)
    #endif
}
