//
//  PhotoKitLibraryService.swift
//  Swipe Out
//
//  Created by Omar Regalado Mendoza on 28/07/26.
//

import Photos
import UIKit


actor PhotoKitLibraryService: PhotoLibraryService {

    private let imageManager = PHCachingImageManager()

    private var assetsByID: [String: PHAsset] = [:]

    // MARK: - Grant Permit

    func requestAuthorization() async -> PhotoAccess {
        let status = await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { @Sendable status in
                continuation.resume(returning: status)
            }
        }
        switch status {
        case .authorized, .limited: return .granted
        default: return .denied
        }
    }

    // MARK: - Bring Photos

    func fetchPhotos() async -> [PhotoItem] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: .image, options: options)

        var items: [PhotoItem] = []
        var map: [String: PHAsset] = [:]
        result.enumerateObjects { asset, _, _ in
            let id = asset.localIdentifier
            map[id] = asset
            items.append(PhotoItem(id: id, fileSize: Self.fileSize(of: asset)))
        }
        assetsByID = map
        return items
    }

    // MARK: - Load Image

    func loadImage(id: String, targetSize: CGSize) async -> UIImage? {
        guard let asset = assetsByID[id] else { return nil }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        return await withCheckedContinuation { continuation in
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { @Sendable image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    // MARK: - Delete

    func deletePhotos(ids: [String]) async throws {
        guard !ids.isEmpty else { return }
        do {
            try await PHPhotoLibrary.shared().performChanges { @Sendable in
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
                PHAssetChangeRequest.deleteAssets(assets)
            }
        } catch {
            if let phError = error as? PHPhotosError, phError.code == .userCancelled {
                throw PhotoLibraryError.cancelled
            }
            throw PhotoLibraryError.failed
        }
    }

    // MARK: - Size in disk

    private static nonisolated func fileSize(of asset: PHAsset) -> Int64 {
        for resource in PHAssetResource.assetResources(for: asset) {
            if let size = resource.value(forKey: "fileSize") as? NSNumber {
                return size.int64Value
            }
        }
        return 0
    }
}
