import UIKit

public protocol ImageDataSource:class {
    func numberOfImages() -> Int
    func imageItem(at index:Int) -> ImageItem
}

class ImageCarouselViewController:UIPageViewController, ImageViewerTransitionViewControllerConvertible {
    
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
    var currentIndex = 0 {
        didSet {
            self.pageControl.currentPage = self.currentIndex
        }
    }
    var indexOffset = 0
    
    var options:[ImageViewerOption] = []
    
    private var onRightNavBarTapped:((Int) -> Void)?
    
    private(set) lazy var navBar: UINavigationBar = {
        let _navBar = UINavigationBar(frame: .zero)
        _navBar.isTranslucent = true
        _navBar.delegate = self
        return _navBar
    }()
    
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
        let _v = UIView()
        if #available(iOS 13.0, *) {
            _v.backgroundColor = .systemBackground
        } else {
            _v.backgroundColor = .white
        }
        _v.alpha = 1.0
        return _v
    }()
    
    private(set) lazy var navItem = UINavigationItem()
    
    private let imageViewerPresentationDelegate = ImageViewerTransitionPresentationManager()
    
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
    
    private func addNavBar() {
        // Add Navigation Bar
        if #available(iOS 13.0, *) {
            let closeBarButton = UIBarButtonItem(
                barButtonSystemItem: .cancel,
                target: self,
                action: #selector(dismiss(_:)))
            navItem.leftBarButtonItem = closeBarButton
        }
        
        navBar.items = [navItem]
        navBar.insert(to: view)
    }
    
    private func addToolBar() {
        pageControl.numberOfPages = self.imageDatasource?.numberOfImages() ?? 0
        pageControl.currentPage = self.currentIndex
        toolBar.addSubview(pageControl)
        
        // Update constraints.
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.heightAnchor.constraint(equalToConstant: 35)
            .isActive = true
        pageControl.topAnchor.constraint(
            equalTo: self.toolBar.topAnchor)
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
            case .closeIcon(let icon):
                navItem.leftBarButtonItem?.image = icon
            case .rightNavItemTitle(let title, let onTap):
                navItem.rightBarButtonItem = UIBarButtonItem(
                    title: title,
                    style: .plain,
                    target: self,
                    action: #selector(diTapRightNavBarItem(_:)))
                onRightNavBarTapped = onTap
            case .rightNavItemIcon(let icon, let onTap):
                navItem.rightBarButtonItem = UIBarButtonItem(
                    image: icon,
                    style: .plain,
                    target: self,
                    action: #selector(diTapRightNavBarItem(_:)))
                onRightNavBarTapped = onTap
            case .indexOffset(let indexOffset):
                self.indexOffset = indexOffset
            }
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        addBackgroundView()
        addNavBar()
        addToolBar()
        applyOptions()
        
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
    private func dismiss(_ sender:UIBarButtonItem) {
        dismissMe(completion: nil)
    }
    
    public func dismissMe(completion: (() -> Void)? = nil) {
        
        guard let collectionView = self.initialSourceView?
                .parentView(of: UICollectionView.self)
        else {
            return
        }
        
        let rowIndex = self.indexOffset + self.currentIndex
        let indexPath = IndexPath(row: rowIndex, section: 0)
        let sourceView = collectionView.cellForItem(at: indexPath)?.contentView
        sourceView?.alpha = 1.0
        
        UIView.animate(withDuration: 0.235, animations: {
            self.view.alpha = 0.0
        }) { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }
    
    deinit {
        initialSourceView?.alpha = 1.0
    }
    
    @objc
    func diTapRightNavBarItem(_ sender:UIBarButtonItem) {
        guard let onTap = onRightNavBarTapped,
            let _firstVC = viewControllers?.first as? ImageViewerController
            else { return }
        onTap(_firstVC.index)
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
            imageItem:  imageDatasource.imageItem(at: newIndex))
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
        
        // Show all other collection view cells
        // (used for the dismiss animation).
        let numberOfRows = collectionView.numberOfItems(inSection: 0)
        for rowIndex in 0..<numberOfRows {
            let indexPath = IndexPath(row: rowIndex, section: 0)
            let collectionViewCell = collectionView.cellForItem(
                at: indexPath)?.contentView
            collectionViewCell?.alpha = 1
        }
        
        // Update the current index.
        self.currentIndex = vc.index
        
        // Scroll the parent collection view to the current item.
        let rowIndex = self.indexOffset + self.currentIndex
        let indexPath = IndexPath(row: rowIndex, section: 0)
        collectionView.scrollToItem(
            at: indexPath,
            at: .left,
            animated: false)
        
        // Hide the currently displayed collection view cell
        // (used for the dismiss animation).
        let collectionViewCell = collectionView.cellForItem(
            at: indexPath)?.contentView
        collectionViewCell?.alpha = 0
    }
}

extension ImageCarouselViewController: UINavigationBarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
