//
//  YPLibraryVC.swift
//  YPImagePicker
//
//  Created by Sacha Durand Saint Omer on 27/10/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import Photos

public class YPLibraryVC: UIViewController, YPPermissionCheckable {
    
    internal weak var delegate: YPLibraryViewDelegate?
    internal var v: YPLibraryView!
    internal var isProcessing = false // true if video or image is in processing state
    internal var multipleSelectionEnabled = false
    internal var initialized = false
    internal var selection = [YPLibrarySelection]()
    internal var currentlySelectedIndex: Int = 0
    internal let mediaManager = LibraryMediaManager()
    internal var latestImageTapped = ""
    internal let panGestureHelper = PanGestureHelper()

    // MARK: - Init
    
    public required init() {
        super.init(nibName: nil, bundle: nil)
        title = YPConfig.wordings.libraryTitle
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setAlbum(_ album: YPAlbum) {
        mediaManager.collection = album.collection
        resetMultipleSelection()
    }
    
    private func resetMultipleSelection() {
        selection.removeAll()
        currentlySelectedIndex = 0
        multipleSelectionEnabled = false
        v.assetViewContainer.setMultipleSelectionMode(on: false)
        delegate?.libraryViewDidToggleMultipleSelection(enabled: false)
        checkLimit()
    }
    
    func initialize() {
        mediaManager.initialize()
        mediaManager.v = v

        if mediaManager.fetchResult != nil {
            return
        }
        
        setupCollectionView()
        registerForLibraryChanges()
        panGestureHelper.registerForPanGesture(on: v)
        registerForTapOnPreview()
        refreshMediaRequest()
        
        v.assetViewContainer.multipleSelectionButton.isHidden = !(YPConfig.maxNumberOfItems > 1)
        v.maxNumberWarningLabel.text = String(format: YPConfig.wordings.warningMaxItemsLimit, YPConfig.maxNumberOfItems)
    }
    
    // MARK: - View Lifecycle
    
    public override func loadView() {
        v = YPLibraryView.xibView()
        view = v
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // When crop area changes in multiple selection mode,
        // we need to update the scrollView values in order to restore
        // them when user selects a previously selected item.
        v.assetZoomableView.cropAreaDidChange = { [unowned self] in
            if self.multipleSelectionEnabled {
                self.updateCropInfo()
            }
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        v.assetViewContainer.squareCropButton
            .addTarget(self,
                       action: #selector(squareCropButtonTapped),
                       for: .touchUpInside)
        v.assetViewContainer.multipleSelectionButton
            .addTarget(self,
                       action: #selector(multipleSelectionButtonTapped),
                       for: .touchUpInside)
        
        // Forces assetZoomableView to have a contentSize.
        // otherwise 0 in first selection triggering the bug : "invalid image size 0x0"
        // Also fits the first element to the square if the onlySquareFromLibrary = true
        if !YPConfig.onlySquareFromLibrary && v.assetZoomableView.contentSize == CGSize(width: 0, height: 0) {
            v.assetZoomableView.setZoomScale(1, animated: false)
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        pausePlayer()
        NotificationCenter.default.removeObserver(self)
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    // MARK: - Crop control
    
    @objc
    func squareCropButtonTapped() {
        doAfterPermissionCheck { [weak self] in
            self?.v.assetViewContainer.squareCropButtonTapped()
        }
    }
    
    // MARK: - Multiple Selection

    @objc
    func multipleSelectionButtonTapped() {
        multipleSelectionEnabled = !multipleSelectionEnabled

        if multipleSelectionEnabled {
            if selection.isEmpty {
                selection = [
                    YPLibrarySelection(index: currentlySelectedIndex,
                                       cropRect: v.currentCropRect(),
                                       scrollViewContentOffset: v.assetZoomableView!.contentOffset,
                                       scrollViewZoomScale: v.assetZoomableView!.zoomScale)
                ]
            }
        } else {
            selection.removeAll()
        }

        v.assetViewContainer.setMultipleSelectionMode(on: multipleSelectionEnabled)
        v.collectionView.reloadData()
        checkLimit()
        delegate?.libraryViewDidToggleMultipleSelection(enabled: multipleSelectionEnabled)
    }
    
    // MARK: - Tap Preview
    
    func registerForTapOnPreview() {
        let tapImageGesture = UITapGestureRecognizer(target: self, action: #selector(tappedImage))
        v.assetViewContainer.addGestureRecognizer(tapImageGesture)
    }
    
    @objc
    func tappedImage() {
        if !panGestureHelper.isImageShown {
            panGestureHelper.resetToOriginalState()
            // no dragup? needed? dragDirection = .up
            v.refreshImageCurtainAlpha()
        }
    }
    
    // MARK: - Permissions
    
    func doAfterPermissionCheck(block:@escaping () -> Void) {
        checkPermissionToAccessPhotoLibrary { hasPermission in
            if hasPermission {
                block()
            }
        }
    }
    
    func checkPermission() {
        checkPermissionToAccessPhotoLibrary { [unowned self] hasPermission in
            if hasPermission && !self.initialized {
                self.initialize()
                self.initialized = true
            }
        }
    }

    // Async beacause will prompt permission if .notDetermined
    // and ask custom popup if denied.
    func checkPermissionToAccessPhotoLibrary(block: @escaping (Bool) -> Void) {
        // Only intilialize picker if photo permission is Allowed by user.
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            block(true)
        case .restricted, .denied:
            let popup = YPPermissionDeniedPopup()
            let alert = popup.popup(cancelBlock: {
                block(false)
            })
            present(alert, animated: true, completion: nil)
        case .notDetermined:
            // Show permission popup and get new status
            PHPhotoLibrary.requestAuthorization { s in
                DispatchQueue.main.async {
                    block(s == .authorized)
                }
            }
        }
    }
    
    func refreshMediaRequest() {
        
        let options = buildPHFetchOptions()
        
        if let collection = mediaManager.collection {
            mediaManager.fetchResult = PHAsset.fetchAssets(in: collection, options: options)
        } else {
            mediaManager.fetchResult = PHAsset.fetchAssets(with: options)
        }
                
        if mediaManager.fetchResult.count > 0 {
            changeAsset(mediaManager.fetchResult[0])
            v.collectionView.reloadData()
            v.collectionView.selectItem(at: IndexPath(row: 0, section: 0),
                                             animated: false,
                                             scrollPosition: UICollectionViewScrollPosition())
        }
        scrollToTop()
    }
    
    func buildPHFetchOptions() -> PHFetchOptions {
        // Sorting condition
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = YPConfig.libraryMediaType.predicate()
        return options
    }
    
    func scrollToTop() {
        tappedImage()
        v.collectionView.contentOffset = CGPoint.zero
    }
    
    // MARK: - ScrollViewDelegate
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == v.collectionView {
            mediaManager.updateCachedAssets(in: self.v.collectionView)
        }
    }
    
    func changeAsset(_ asset: PHAsset) {
        mediaManager.selectedAsset = asset
        latestImageTapped = asset.localIdentifier
        delegate?.libraryViewStartedLoading()
        
        DispatchQueue.global(qos: .userInitiated).async {
            switch asset.mediaType {
            case .image:
                self.v.assetZoomableView.setImage(asset,
                                                  mediaManager: self.mediaManager,
                                                  storedCropPosition: self.fetchStoredCrop()) {
                    self.v.hideLoader()
                    self.v.hideGrid()
                    self.delegate?.libraryViewFinishedLoading()
                    self.v.assetViewContainer.refreshSquareCropButton()
                }
            case .video:
                self.v.assetZoomableView.setVideo(asset,
                                                  mediaManager: self.mediaManager,
                                                  storedCropPosition: self.fetchStoredCrop()) {
                    self.v.hideLoader()
                    self.v.hideGrid()
                    self.delegate?.libraryViewFinishedLoading()
                    self.v.assetViewContainer.refreshSquareCropButton()
                }
            case .audio, .unknown:
                ()
            }
        }
    }
    
    // MARK: - Verification
    
    private func fitsVideoLengthLimits(asset: PHAsset) -> Bool {
        guard asset.mediaType == .video else {
            return true
        }
        
        let tooLong = asset.duration > YPConfig.videoFromLibraryTimeLimit
        let tooShort = asset.duration < YPConfig.videoMinimumTimeLimit
        
        if tooLong || tooShort {
            DispatchQueue.main.async {
                let alert = tooLong ? YPAlert.videoTooLongAlert() : YPAlert.videoTooShortAlert()
                self.present(alert, animated: true, completion: nil)
            }
            return false
        }
        
        return true
    }
    
    // MARK: - Stored Crop Position
    
    internal func updateCropInfo(shouldUpdateOnlyIfNil: Bool = false) {
        guard let selectedAssetIndex = selection.index(where: { $0.index == currentlySelectedIndex }) else {
            return
        }
        
        if shouldUpdateOnlyIfNil && selection[selectedAssetIndex].scrollViewContentOffset != nil {
            return
        }
        
        // Fill new values
        var selectedAsset = selection[selectedAssetIndex]
        selectedAsset.scrollViewContentOffset = v.assetZoomableView.contentOffset
        selectedAsset.scrollViewZoomScale = v.assetZoomableView.zoomScale
        selectedAsset.cropRect = v.currentCropRect()
        
        // Replace
        selection.remove(at: selectedAssetIndex)
        selection.insert(selectedAsset, at: selectedAssetIndex)
    }
    
    internal func fetchStoredCrop() -> YPLibrarySelection? {
        if self.multipleSelectionEnabled,
            self.selection.contains(where: { $0.index == self.currentlySelectedIndex }) {
            guard let selectedAssetIndex = self.selection
                .index(where: { $0.index == self.currentlySelectedIndex }) else {
                return nil
            }
            return self.selection[selectedAssetIndex]
        }
        return nil
    }
    
    internal func hasStoredCrop(index: Int) -> Bool {
        return self.selection.contains(where: { $0.index == index })
    }
    
    // MARK: - Fetching Media
    
    private func fetchImageAndCrop(for asset: PHAsset,
                                   withCropRect: CGRect? = nil,
                                   callback: @escaping (_ photo: UIImage) -> Void) {
        delegate?.libraryViewStartedLoading()
        let cropRect = withCropRect ?? DispatchQueue.main.sync { v.currentCropRect() }
        let ts = targetSize(for: asset, cropRect: cropRect)
        mediaManager.imageManager?.fetchImage(for: asset, cropRect: cropRect, targetSize: ts, callback: callback)
    }
    
    private func checkVideoLengthAndCrop(for asset: PHAsset,
                                         withCropRect: CGRect? = nil,
                                         callback: @escaping (_ videoURL: URL) -> Void) {
        if fitsVideoLengthLimits(asset: asset) == true {
            delegate?.libraryViewStartedLoading()
            let normalizedCropRect = withCropRect ?? DispatchQueue.main.sync { v.currentCropRect() }
            let ts = targetSize(for: asset, cropRect: normalizedCropRect)
            let xCrop: CGFloat = normalizedCropRect.origin.x * CGFloat(asset.pixelWidth)
            let yCrop: CGFloat = normalizedCropRect.origin.y * CGFloat(asset.pixelHeight)
            let resultCropRect = CGRect(x: xCrop,
                                        y: yCrop,
                                        width: ts.width,
                                        height: ts.height)
            mediaManager.fetchVideoUrlAndCrop(for: asset, cropRect: resultCropRect, callback: callback)
        }
    }
    
    public func selectedMedia(photoCallback: @escaping (_ photo: UIImage) -> Void,
                              videoCallback: @escaping (_ videoURL: URL) -> Void,
                              multipleItemsCallback: @escaping (_ items: [YPMediaItem]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            
            // Multiple selection
            if self.multipleSelectionEnabled && self.selection.count > 1 {
                let selectedAssets: [(asset: PHAsset, cropRect: CGRect?)] = self.selection.map {
                    return (self.mediaManager.fetchResult[$0.index], $0.cropRect)
                }
                
                // Check video length
                for asset in selectedAssets {
                    if self.fitsVideoLengthLimits(asset: asset.asset) == false {
                        return
                    }
                }
                
                // Fill result media items array
                var resultMediaItems: [YPMediaItem] = []
                let asyncGroup = DispatchGroup()
                
                for asset in selectedAssets {
                    asyncGroup.enter()
                    
                    switch asset.asset.mediaType {
                    case .image:
                        self.fetchImageAndCrop(for: asset.asset, withCropRect: asset.cropRect) { image in
                            let resizedImage = self.resizedImageIfNeeded(image: image)
                            let photo = YPMediaPhoto(image: resizedImage)
                            resultMediaItems.append(YPMediaItem.photo(p: photo))
                            asyncGroup.leave()
                        }
                        
                    case .video:
                        self.checkVideoLengthAndCrop(for: asset.asset, withCropRect: asset.cropRect) { videoURL in
                            let videoItem = YPMediaVideo(thumbnail: thumbnailFromVideoPath(videoURL),
                                                         videoURL: videoURL)
                            resultMediaItems.append(YPMediaItem.video(v: videoItem))
                            asyncGroup.leave()
                        }
                    default:
                        break
                    }
                }
                
                asyncGroup.notify(queue: .main) {
                    multipleItemsCallback(resultMediaItems)
                    self.delegate?.libraryViewFinishedLoading()
                }
        } else {
                let asset = self.mediaManager.selectedAsset!
                switch asset.mediaType {
                case .video:
                    self.checkVideoLengthAndCrop(for: asset, callback: { videoURL in
                        DispatchQueue.main.async {
                            self.delegate?.libraryViewFinishedLoading()
                            videoCallback(videoURL)
                        }
                    })
                case .image:
                    self.fetchImageAndCrop(for: asset) { image in
                        DispatchQueue.main.async {
                            self.delegate?.libraryViewFinishedLoading()
                            let resizedImage = self.resizedImageIfNeeded(image: image)
                            photoCallback(resizedImage)
                        }
                    }
                case .audio, .unknown:
                    return
                }
            }
        }
    }
    
    // MARK: - TargetSize
    
    private func targetSize(for asset: PHAsset, cropRect: CGRect) -> CGSize {
        let width = floor(CGFloat(asset.pixelWidth) * cropRect.width)
        let height = floor(CGFloat(asset.pixelHeight) * cropRect.height)
        return CGSize(width: width, height: height)
    }
    
    // Reduce image size further if needed libraryTargetImageSize is capped.
    func resizedImageIfNeeded(image: UIImage) -> UIImage {
        if case let YPLibraryImageSize.cappedTo(size: capped) = YPConfig.libraryTargetImageSize {
            let size = cappedSize(for: image.size, cappedAt: capped)
            if let resizedImage = image.resized(to: size) {
                return resizedImage
            }
        }
        return image
    }
    
    private func cappedSize(for size: CGSize, cappedAt: CGFloat) -> CGSize {
        var cappedWidth: CGFloat = 0
        var cappedHeight: CGFloat = 0
        if size.width > size.height {
            // Landscape
            let heightRatio = size.height / size.width
            cappedWidth = min(size.width, cappedAt)
            cappedHeight = cappedWidth * heightRatio
        } else if size.height > size.width {
            // Portrait
            let widthRatio = size.width / size.height
            cappedHeight = min(size.height, cappedAt)
            cappedWidth = cappedHeight * widthRatio
        } else {
            // Squared
            cappedWidth = min(size.width, cappedAt)
            cappedHeight = min(size.height, cappedAt)
        }
        return CGSize(width: cappedWidth, height: cappedHeight)
    }
    
    // MARK: - Player
    
    func pausePlayer() {
        v.assetZoomableView.videoView.pause()
    }
    
    // MARK: - Deinit
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
}

extension UIImage {
    
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
