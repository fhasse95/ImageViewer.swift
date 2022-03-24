import UIKit

public enum ImageViewerOption {
    case indexOffset(Int)
    case deleteButton(onTap: ((ImageCarouselViewController) -> Void)?)
    case transitionType(ImageViewerTransitionType)
}

public enum ImageViewerTransitionType {
    case none
    case move
}
