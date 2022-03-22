import UIKit

public enum ImageViewerOption {
    
    case indexOffset(Int)
    case deleteButton(onTap: ((ImageCarouselViewController) -> Void)?)
}
