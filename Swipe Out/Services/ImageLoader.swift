//
//  ImageLoader.swift
//  Swipe Out
//
//  Created by Omar Regalado Mendoza on 28/07/26.
//

import UIKit

@MainActor
final class ImageLoader {
    private let library: PhotoLibraryService
    private var cache: [String: UIImage] = [:]
    private let targetSize = CGSize(width: 1000, height: 1000)

    init(library: PhotoLibraryService) {
        self.library = library
    }

    func cachedImage(for id: String) -> UIImage? {
        cache[id]
    }

    func image(for id: String) async -> UIImage? {
        if let cached = cache[id] { return cached }
        let image = await library.loadImage(id: id, targetSize: targetSize)
        if let image { cache[id] = image }
        return image
    }

    
    func preload(_ ids: [String]) {
        for id in ids where cache[id] == nil {
            Task { _ = await image(for: id) }
        }
    }


    func keepOnly(_ ids: [String]) {
        let keep = Set(ids)
        cache = cache.filter { keep.contains($0.key) }
    }
}
