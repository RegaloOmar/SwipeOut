//
//  PhotoKitLibraryService.swift
//  Swipe Out
//
//  Created by Omar Regalado Mendoza on 28/07/26.
//

import Photos
import UIKit
import PhotosUI
import Foundation


private nonisolated final class ResumeGuard: @unchecked Sendable {
    private var claimed = false
    private let lock = NSLock()
    func claim() -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard !claimed else { return false }
        claimed = true
        return true
    }
}

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
        case .authorized:
                return .full
        case .limited:
                return .limited
        default:
                return .denied
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
            items.append(PhotoItem(id: id))
        }
        assetsByID = map
        return items
    }

    // MARK: - File Size

    func fileSize(for id: String) async -> Int64 {
        guard let asset = assetsByID[id] else { return 0 }
        return Self.fileSize(of: asset)
    }

    // MARK: - Load Image

    func loadImage(id: String, targetSize: CGSize) async -> UIImage? {
        
        guard let asset = assetsByID[id] else { return nil }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        let resumeGuard = ResumeGuard()
        return await withCheckedContinuation { continuation in
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { @Sendable image, _ in
                guard resumeGuard.claim() else { return }
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
    

    func presentLimitedPicker() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task { @MainActor in
                guard let vc = Self.topViewController() else {
                    continuation.resume()
                    return
                }
                PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: vc) { _ in
                    continuation.resume()
                }
            }
        }
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }

        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
