import UIKit

public protocol ImageDataSource: AnyObject {
    func numberOfImages() -> Int
    func imageItem(at index:Int) -> ImageItem
}

public class ImageCarouselViewController:UIPageViewController, ImageViewerTransitionViewControllerConvertible {
    
    var transitionSourceRect: CGRect? = nil
    
    var hideControls: Bool = false {
        didSet {
            UIView.animate(withDuration: UINavigationController.hideShowBarDuration) {
                self.navBar.alpha = self.hideControls ? 0 : 1
                self.toolBar.alpha = self.hideControls ? 0 : 1
                self.updateBackgroundView()
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    
    public override var prefersStatusBarHidden: Bool {
        return self.hideControls
    }
    
    unowned var initialSourceView: UIImageView?
    var sourceView: UIImageView? {
        guard let vc = viewControllers?.first as? ImageViewerController else {
            return nil
        }
        return initialIndex == vc.index ? initialSourceView : nil
    }
    
    var targetView: UIImageView? {
        guard let vc = viewControllers?.first as? ImageViewerController else {
            return nil
        }
        return vc.imageView
    }
    
    weak var imageDatasource:ImageDataSource?
    
    var initialIndex = 0
    public var currentIndex = 0 {
        didSet {
            self.pageControl.currentPage = self.currentIndex
        }
    }
    var indexOffset = 0
    
    var imageContentMode: UIView.ContentMode = .scaleAspectFill
    var options:[ImageViewerOption] = []
    
    private var onDeleteButtonTapped:((ImageCarouselViewController) -> Void)?
    
    private(set) lazy var navBar: UINavigationBar = {
        let _navBar = UINavigationBar(frame: .zero)
        _navBar.isTranslucent = true
        _navBar.delegate = self
        return _navBar
    }()
    
    private var deleteBarButtonItem: UIBarButtonItem?
    private(set) lazy var toolBar: UIToolbar = {
        let _toolBar = UIToolbar(frame: .zero)
        _toolBar.isTranslucent = true
        return _toolBar
    }()
    
    private(set) lazy var pageControl: UIPageControl = {
        let _pageControl = UIPageControl(frame: .zero)
        if #available(iOS 14.0, *) {
            _pageControl.allowsContinuousInteraction = false
        }
        
        if #available(iOS 13.0, *) {
            _pageControl.pageIndicatorTintColor = .systemFill
            _pageControl.currentPageIndicatorTintColor = .secondaryLabel
        }
        return _pageControl
    }()
    
    private(set) lazy var backgroundView:UIView? = {
        let _backgroundView = UIView()
        switch self.traitCollection.userInterfaceStyle {
        case .dark:
            _backgroundView.backgroundColor = .black
        default:
            _backgroundView.backgroundColor = .white
        }
        _backgroundView.alpha = 1.0
        return _backgroundView
    }()
    
    private(set) lazy var navItem = UINavigationItem()
    
    private let imageViewerPresentationDelegate: ImageViewerTransitionPresentationManager
    
    public init(
        sourceView:UIImageView,
        imageDataSource: ImageDataSource?,
        options:[ImageViewerOption] = [],
        initialIndex:Int = 0) {
        
        self.initialSourceView = sourceView
        self.initialIndex = initialIndex
        self.currentIndex = initialIndex
        self.options = options
        self.imageDatasource = imageDataSource
        let pageOptions = [UIPageViewController.OptionsKey.interPageSpacing: 20]
        
        var _imageContentMode = imageContentMode
        options.forEach {
            switch $0 {
            case .contentMode(let contentMode):
                _imageContentMode = contentMode
            default:
                break
            }
        }
        imageContentMode = _imageContentMode
        
        self.imageViewerPresentationDelegate = ImageViewerTransitionPresentationManager(imageContentMode: imageContentMode)
        super.init(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: pageOptions)
        
        transitioningDelegate = imageViewerPresentationDelegate
        modalPresentationStyle = .custom
        modalPresentationCapturesStatusBarAppearance = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func traitCollectionDidChange(
        _ previousTraitCollection: UITraitCollection?) {
            
        super.traitCollectionDidChange(previousTraitCollection)
        self.updateBackgroundView()
    }
    
    private func updateBackgroundView() {
        if self.hideControls || self.traitCollection.userInterfaceStyle == .dark {
            self.backgroundView?.backgroundColor = .black
        } else {
            self.backgroundView?.backgroundColor = .white
        }
    }
    
    private func addNavBar() {
        // Add Navigation Bar
        if #available(iOS 13.0, *) {
            let doneBarButton = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(dismiss(_:)))
            navItem.rightBarButtonItem = doneBarButton
        }
        
        navBar.items = [navItem]
        navBar.insert(to: view)
    }
    
    private func addToolBar() {
        let numberOfPages = self.imageDatasource?.numberOfImages() ?? 0
        pageControl.numberOfPages = numberOfPages
        pageControl.isHidden = numberOfPages == 1
        pageControl.currentPage = self.currentIndex
        toolBar.addSubview(pageControl)
        
        if #available(iOS 13.0, *) {
            var items = [UIBarButtonItem]()
            items.append(
                UIBarButtonItem(
                    barButtonSystemItem: .action,
                    target: self,
                    action: #selector(shareImage(_:)))
            )
            items.append(
                UIBarButtonItem(
                    barButtonSystemItem: .flexibleSpace,
                    target: nil,
                    action: nil)
            )
            toolBar.items = items
        }
        
        // Update constraints.
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.centerYAnchor.constraint(
            equalTo: self.toolBar.centerYAnchor)
            .isActive = true
        pageControl.heightAnchor.constraint(
            equalToConstant: 50)
            .isActive = true
        pageControl.bottomAnchor.constraint(
            equalTo: self.toolBar.bottomAnchor)
            .isActive = true
        pageControl.leadingAnchor.constraint(
            equalTo: self.toolBar.leadingAnchor)
            .isActive = true
        pageControl.trailingAnchor.constraint(
            equalTo: self.toolBar.trailingAnchor)
            .isActive = true
        
        view.addSubview(toolBar)
        
        // Update constraints.
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        toolBar.bottomAnchor.constraint(
            equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
            .isActive = true
        toolBar.leadingAnchor.constraint(
            equalTo: self.view.safeAreaLayoutGuide.leadingAnchor)
            .isActive = true
        toolBar.trailingAnchor.constraint(
            equalTo: self.view.safeAreaLayoutGuide.trailingAnchor)
            .isActive = true
        
        // Add the delete bar button item if necessary.
        if let deleteBarButtonItem = deleteBarButtonItem {
            toolBar.items?.append(deleteBarButtonItem)
        }
    }
    
    private func addBackgroundView() {
        guard let backgroundView = backgroundView else { return }
        view.addSubview(backgroundView)
        backgroundView.bindFrameToSuperview()
        view.sendSubviewToBack(backgroundView)
    }
    
    private func applyOptions() {
        
        options.forEach {
            switch $0 {
            case .deleteButton(let onTap):
                self.deleteBarButtonItem = UIBarButtonItem(
                    barButtonSystemItem: .trash,
                    target: self,
                    action: #selector(deleteImage(_:)))
                self.deleteBarButtonItem?.tintColor = .systemRed
                self.onDeleteButtonTapped = onTap
            case .indexOffset(let indexOffset):
                self.indexOffset = indexOffset
            case .transitionSourceRect(let sourceRect):
                self.transitionSourceRect = sourceRect
            case .theme(let theme):
                self.theme = theme
            case .contentMode(let contentMode):
                self.imageContentMode = contentMode
            case .closeIcon(let icon):
                self.navItem.leftBarButtonItem?.image = icon
            case .rightNavItemTitle(let title, let onTap):
                self.navItem.rightBarButtonItem = UIBarButtonItem(
                    title: title,
                    style: .plain,
                    target: self,
                    action: #selector(diTapRightNavBarItem(_:)))
                self.onRightNavBarTapped = onTap
            case .rightNavItemIcon(let icon, let onTap):
                self.navItem.rightBarButtonItem = UIBarButtonItem(
                    image: icon,
                    style: .plain,
                    target: self,
                    action: #selector(diTapRightNavBarItem(_:)))
                self.onRightNavBarTapped = onTap
            }
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.applyOptions()
        DispatchQueue.main.async {
            self.addBackgroundView()
            self.addNavBar()
            self.addToolBar()
        }
        
        dataSource = self
        delegate = self
        
        if let imageDatasource = imageDatasource {
            let initialVC:ImageViewerController = .init(
                index: initialIndex,
                imageItem: imageDatasource.imageItem(at: initialIndex))
            setViewControllers([initialVC], direction: .forward, animated: true)
        }
    }
    
    @objc
    private func shareImage(_ sender:UIBarButtonItem) {
        
        guard let imageItem = self.imageDatasource?.imageItem(
            at: self.currentIndex) as? ImageItem
        else {
            return
        }
        
        var imageToShare: UIImage?
        switch imageItem {
        case .image(let image, let thumbnailImage):
            imageToShare = image
        default:
            break
        }
        
        guard let imageToShare = imageToShare
        else {
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: [imageToShare],
            applicationActivities: nil)
        activityViewController.popoverPresentationController?
            .sourceView = self.view
        
        self.present(
            activityViewController,
            animated: true,
            completion: nil)
    }
    
    @objc
    private func deleteImage(_ sender:UIBarButtonItem) {
        onDeleteButtonTapped?(self)
    }
    
    @objc
    private func dismiss(_ sender:UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    public func dismissView(completion: (() -> Void)? = nil) {
        
        guard let collectionView = self.initialSourceView?
                .parentView(of: UICollectionView.self)
        else {
            return
        }
        
        // Show all collection view cells again.
        self.resetParentScrollViewCellVisibility()
        
        UIView.animate(withDuration: 0.235, animations: {
            self.view.alpha = 0.0
        }) { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }
    
    deinit {
        initialSourceView?.alpha = 1.0
    }
}

extension ImageCarouselViewController:UIPageViewControllerDataSource {
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let vc = viewController as? ImageViewerController else { return nil }
        guard let imageDatasource = imageDatasource else { return nil }
        guard vc.index > 0 else { return nil }
 
        let newIndex = vc.index - 1
        return ImageViewerController.init(
            index: newIndex,
            imageItem: imageDatasource.imageItem(at: newIndex))
    }
    
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let vc = viewController as? ImageViewerController else { return nil }
        guard let imageDatasource = imageDatasource else { return nil }
        guard vc.index <= (imageDatasource.numberOfImages() - 2) else { return nil }
        
        let newIndex = vc.index + 1
        return ImageViewerController.init(
            index: newIndex,
            imageItem: imageDatasource.imageItem(at: newIndex))
    }
}

extension ImageCarouselViewController: UIPageViewControllerDelegate {
    
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool) {
        
        guard completed,
              let vc = pageViewController.viewControllers?.first
                as? ImageViewerController,
              let collectionView = self.initialSourceView?
                .parentView(of: UICollectionView.self)
        else {
            return
        }
        
        // Show all collection view cells again.
        self.resetParentScrollViewCellVisibility()
        
        // Update the current index.
        self.currentIndex = vc.index
        
        // Scroll the parent collection view to the current item.
        self.scrollParentScrollViewToCurrentItem()
        
        // Hide the currently displayed collection view cell
        // (used for the dismiss animation).
        self.hideCurrentParentScrollViewCell()
    }
    
    public func scrollParentScrollViewToCurrentItem(
        onlyScrollIfNecessary: Bool = true) {
        
        let rowIndex = self.indexOffset + self.currentIndex
        let indexPath = IndexPath(row: rowIndex, section: 0)
        
        guard let collectionView = self.initialSourceView?
                .parentView(of: UICollectionView.self),
              let collectionViewCell = collectionView.cellForItem(
                at: indexPath)
        else {
            return
        }
        
        // Only scroll when the cell is not fully visible (e.g. cut off).
        let completelyVisible =
            collectionView.bounds.contains(
                collectionViewCell.frame)
        
        let shouldScroll = !completelyVisible
        if shouldScroll || !onlyScrollIfNecessary {
            DispatchQueue.main.async {
                collectionView.scrollToItem(
                    at: indexPath,
                    at: .left,
                    animated: false)
            }
        }
    }
    
    public func resetParentScrollViewCellVisibility() {
        
        guard let collectionView = self.initialSourceView?
                .parentView(of: UICollectionView.self)
        else {
            return
        }
        
        // Show all collection view cells again.
        let numberOfRows = collectionView.numberOfItems(inSection: 0)
        for rowIndex in 0..<numberOfRows {
            let indexPath = IndexPath(row: rowIndex, section: 0)
            let collectionViewCell = collectionView.cellForItem(
                at: indexPath)?.contentView
            
            DispatchQueue.main.async {
                collectionViewCell?.alpha = 1
            }
        }
    }
    
    public func hideCurrentParentScrollViewCell() {
        
        guard let collectionView = self.initialSourceView?
                .parentView(of: UICollectionView.self)
        else {
            return
        }
        
        // Hide the currently displayed collection view cell
        // (used for the dismiss animation).
        let rowIndex = self.indexOffset + self.currentIndex
        let indexPath = IndexPath(row: rowIndex, section: 0)
        let collectionViewCell = collectionView.cellForItem(
            at: indexPath)?.contentView
        
        DispatchQueue.main.async {
            collectionViewCell?.alpha = 0
        }
    }
}

extension ImageCarouselViewController: UINavigationBarDelegate {
    
    public func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
