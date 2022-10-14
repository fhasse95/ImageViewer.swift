import UIKit

extension UIImageView {
    
    // Data holder tap recognizer
    public class TapWithDataRecognizer:UITapGestureRecognizer {
        weak var from:UIViewController?
        var imageDatasource:ImageDataSource?
        var initialIndex:Int = 0
        var options:[ImageViewerOption] = []
    }
    
    private var vc:UIViewController? {
        guard let rootVC = UIApplication.shared.keyWindow?.rootViewController
            else { return nil }
        return rootVC.presentedViewController != nil ? rootVC.presentedViewController : rootVC
    }
    
    public func setupImageViewer(
        options:[ImageViewerOption] = [],
        from:UIViewController? = nil) {
        setup(
            datasource: SimpleImageDatasource(imageItems: [.image(image!, image!)]),
            options: options,
            from: from)
    }
    
    #if canImport(SDWebImage)
    public func setupImageViewer(
        url:URL,
        initialIndex:Int = 0,
        placeholder: UIImage? = nil,
        options:[ImageViewerOption] = [],
        from:UIViewController? = nil) {
        
        let datasource = SimpleImageDatasource(
            imageItems: [url].compactMap {
                ImageItem.url($0, placeholder: placeholder)
        })
        setup(
            datasource: datasource,
            initialIndex: initialIndex,
            options: options,
            from: from)
    }
    #endif
    
    public func setupImageViewer(
        images: [UIImage],
        thumbnailImages: [UIImage],
        initialIndex:Int = 0,
        options: [ImageViewerOption] = [],
        from: UIViewController? = nil) {
            
        var imageItems = [ImageItem]()
        for index in 0..<images.count {
            imageItems.append(
                ImageItem.image(
                    images[index],
                    thumbnailImages[index]
                ))
        }
        
        let datasource = SimpleImageDatasource(
            imageItems: imageItems)
        setup(
            datasource: datasource,
            initialIndex: initialIndex,
            options: options,
            from: from)
    }
    
    #if canImport(SDWebImage)
    public func setupImageViewer(
        urls:[URL],
        initialIndex:Int = 0,
        options:[ImageViewerOption] = [],
        placeholder: UIImage? = nil,
        from:UIViewController? = nil) {
        
        let datasource = SimpleImageDatasource(
            imageItems: urls.compactMap {
                ImageItem.url($0, placeholder: placeholder)
        })
        setup(
            datasource: datasource,
            initialIndex: initialIndex,
            options: options,
            from: from)
    }
    #endif
    
    public func setupImageViewer(
        datasource:ImageDataSource,
        initialIndex:Int = 0,
        options:[ImageViewerOption] = [],
        from:UIViewController? = nil) {
        
        setup(
            datasource: datasource,
            initialIndex: initialIndex,
            options: options,
            from: from)
    }
    
    private func setup(
        datasource:ImageDataSource?,
        initialIndex:Int = 0,
        options:[ImageViewerOption] = [],
        from: UIViewController? = nil) {
        
        var _tapRecognizer:TapWithDataRecognizer?
        gestureRecognizers?.forEach {
            if let _tr = $0 as? TapWithDataRecognizer {
                // if found, just use existing
                _tapRecognizer = _tr
            }
        }
        
        isUserInteractionEnabled = true
        contentMode = .scaleAspectFill
        clipsToBounds = true
        
        if _tapRecognizer == nil {
            _tapRecognizer = TapWithDataRecognizer(
                target: self, action: #selector(showImageViewer(_:)))
            _tapRecognizer!.numberOfTouchesRequired = 1
            _tapRecognizer!.numberOfTapsRequired = 1
        }
        
        // Pass the Data
        _tapRecognizer!.imageDatasource = datasource
        _tapRecognizer!.initialIndex = initialIndex
        _tapRecognizer!.options = options
        _tapRecognizer!.from = from
        addGestureRecognizer(_tapRecognizer!)
            
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        
        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            if let imageCarouselViewController = topController
                as? ImageCarouselViewController,
               let collectionView = imageCarouselViewController.initialSourceView?
                .parentView(of: UICollectionView.self) {
                
                // Update the data source.
                imageCarouselViewController.imageDatasource = datasource
                
                DispatchQueue.main.async {
                    // Show all collection view cells again.
                    imageCarouselViewController.resetParentScrollViewCellVisibility()
                    
                    // Hide the currently displayed collection view cell
                    // (used for the dismiss animation).
                    imageCarouselViewController.hideCurrentParentScrollViewCell()
                }
            }
        }
    }
    
    public func showImageViewer(
        transitionSourceRect: CGRect? = .zero) {
        
        if let tapWithDataRecognizer = self.gestureRecognizers?
            .first(where: { $0 is TapWithDataRecognizer })
            as? TapWithDataRecognizer {
            
            func removeAllTemporaryOptions() {
                for (index, option) in tapWithDataRecognizer.options.enumerated() {
                    guard tapWithDataRecognizer.options.count > index
                    else {
                        continue
                    }
                    
                    switch option {
                    case .transitionSourceRect(_):
                        tapWithDataRecognizer.options.remove(at: index)
                    default:
                        break
                    }
                }
            }
            
            if let transitionSourceRect = transitionSourceRect {
                removeAllTemporaryOptions()
                tapWithDataRecognizer.options.append(.transitionSourceRect(transitionSourceRect))
                removeAllTemporaryOptions()
            }
            
            self.showImageViewer(tapWithDataRecognizer)
        }
    }
    
    @objc
    private func showImageViewer(_ sender: TapWithDataRecognizer) {
        guard let sourceView = sender.view as? UIImageView else { return }
        
        let imageCarousel = ImageCarouselViewController.init(
            sourceView: sourceView,
            imageDataSource: sender.imageDatasource,
            options: sender.options,
            initialIndex: sender.initialIndex)
        
        let presentFromVC = sender.from ?? vc
        presentFromVC?.present(imageCarousel, animated: true, completion: {
            imageCarousel.hideCurrentParentScrollViewCell()
        })
    }
}
