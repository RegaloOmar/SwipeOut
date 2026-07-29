//
//  PhotoKitLibraryService.swift
//  Swipe Out
//
//  Created by Omar Regalado Mendoza on 28/07/26.
//

import Photos
import UIKit
import PhotosUI


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
            items.append(PhotoItem(id: id))       // sin tamaño: carga rápida a cualquier escala
        }
        assetsByID = map
        return items
    }

    // MARK: - File Size (bajo demanda, solo para lo que se marca)

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
    
    /// Muestra el selector nativo de "fotos seleccionadas" y espera a que se cierre.
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

    /// Encuentra el view controller visible para presentar desde SwiftUI.
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
