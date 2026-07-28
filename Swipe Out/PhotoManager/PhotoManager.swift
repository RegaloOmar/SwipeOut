//
//  PhotoManager.swift
//  Swipe Out
//
//  Created by Omar Regalado Mendoza on 21/07/26.
//

import Photos
import SwiftUI

@MainActor
@Observable
final class PhotoManager {
// MARK: - Enum for state of authorization
    enum AuthState {
        case unknown
        case authorized
        case denied
    }
    
    //MARK: - Vars and Constants
    var authState: AuthState = .unknown
    
    private var assets: [PHAsset] = []
    
    var currentIndex = 0
    
    var currentImage: UIImage?
    var total: Int { assets.count }
    var isFinished: Bool { currentIndex >= assets.count }
    
    private let imageManager = PHCachingImageManager()
    private var imageCache: [Int: UIImage] = [:]
    
    private(set) var bytesToDelete: Int64 = 0
    
    //MARK: - Decisions
    
    private(set) var toDelete: [PHAsset] = []
    private var decisionHistory: [Bool] = []
    
    var toDeleteCount: Int { toDelete.count }
    var canUndo: Bool { !decisionHistory.isEmpty }
    
    func handleDecision(delete: Bool) {
        guard currentIndex < assets.count else { return }
        let asset = assets[currentIndex]
        if delete {
            toDelete.append(assets[currentIndex])
            bytesToDelete += fileSize(of: asset)
        }
        decisionHistory.append(delete)
        currentIndex += 1
        loadCurrentImage()
    }
    
    var freedSpaceText: String {
        bytesToDelete.formatted(.byteCount(style: .file))
    }

    private func fileSize(of asset: PHAsset) -> Int64 {
        for resource in PHAssetResource.assetResources(for: asset) {
            if let size = resource.value(forKey: "fileSize") as? NSNumber {
                return size.int64Value
            }
        }
        return 0
    }
    
    //MARK: - Functions
    
    func undo() {
        guard let ultimaFueBorrar = decisionHistory.popLast() else { return }
        currentIndex -= 1
        if ultimaFueBorrar {
            toDelete.removeLast()
            bytesToDelete = max(0, bytesToDelete - fileSize(of: assets[currentIndex]))
        }
        loadCurrentImage()
    }
    
    func requestAccess() async {
        let status = await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status)
            }
        }
        
        switch status {
            case .authorized, .limited:
                authState = .authorized
                loadAssets()
            default:
                authState = .denied
        }
    }
    
    private func loadAssets() {
        let options = PHFetchOptions()
        
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var fetched: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            fetched.append(asset)
        }
        assets = fetched
        currentIndex = 0
        loadCurrentImage()
    }
    
    private func requestImage(at index: Int, completion: ((UIImage?) -> Void)? = nil) {
        guard index >= 0, index < assets.count else {
            completion?(nil)
            return
        }
        if let cached = imageCache[index] {
            completion?(cached)
            return
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        imageManager.requestImage(
            for: assets[index],
            targetSize: CGSize(width: 1000, height: 1000),
            contentMode: .aspectFit,
            options: options
        ) { [weak self] image, _ in
            Task { @MainActor in
                guard let self, let image else { return }
                self.imageCache[index] = image
                completion?(image)
            }
        }
    }

    private func loadCurrentImage() {
        guard currentIndex < assets.count else {
            currentImage = nil
            return
        }

        let index = currentIndex
        requestImage(at: index) { [weak self] image in
            guard let self, self.currentIndex == index else { return }
            self.currentImage = image
        }

        requestImage(at: index + 1)
        requestImage(at: index - 1)

        imageCache = imageCache.filter { abs($0.key - index) <= 3 }
    }
    
    func advance() {
        currentIndex += 1
        loadCurrentImage()
    }
    
    func deleteMarkedPhotos() async -> Bool {
        guard !toDelete.isEmpty else { return true }

        let ids = toDelete.map(\.localIdentifier)

        do {
            try await PHPhotoLibrary.shared().performChanges { @Sendable in
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
                PHAssetChangeRequest.deleteAssets(assets)
            }
            toDelete.removeAll()
            decisionHistory.removeAll()
            bytesToDelete = 0 
            return true
        } catch {
            return false
        }
    }
    
    func restart() {
        toDelete.removeAll()
        decisionHistory.removeAll()
        bytesToDelete = 0
        imageCache.removeAll()
        loadAssets()
    }
    
}
