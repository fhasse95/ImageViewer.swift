import UIKit

public enum ImageViewerOption {
    case indexOffset(Int)
    case deleteButton(onTap: ((ImageCarouselViewController) -> Void)?)
    case transitionSourceRect(CGRect)
    case theme(ImageViewerTheme)
    case contentMode(UIView.ContentMode)
    case closeIcon(UIImage)
    case rightNavItemTitle(String, onTap: ((Int) -> Void)?)
    case rightNavItemIcon(UIImage, onTap: ((Int) -> Void)?)
}
