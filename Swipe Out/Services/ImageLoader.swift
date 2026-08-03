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
    private var inFlight: [String: Task<UIImage?, Never>] = [:]
    private let targetSize = CGSize(width: 1320, height: 1760)

    init(library: PhotoLibraryService) {
        self.library = library
    }

    func cachedImage(for id: String) -> UIImage? {
        cache[id]
    }

    func image(for id: String) async -> UIImage? {
        if let cached = cache[id] { return cached }
        if let existing = inFlight[id] { return await existing.value }

        let task = Task { [library, targetSize] in
            await library.loadImage(id: id, targetSize: targetSize)
        }
        inFlight[id] = task
        let image = await task.value
        inFlight[id] = nil

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
