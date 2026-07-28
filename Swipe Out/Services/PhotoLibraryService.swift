//
//  PhotoLibraryService.swift
//  Swipe Out
//
//  Created by Omar Regalado Mendoza on 28/07/26.
//

import UIKit

enum PhotoAccess {
    case granted
    case denied
}


enum PhotoLibraryError: Error {
    case deletionFailed
}

protocol PhotoLibraryService: Sendable {
    func requestAuthorization() async -> PhotoAccess
    func fetchPhotos() async -> [PhotoItem]
    func loadImage(id: String, targetSize: CGSize) async -> UIImage?
    func deletePhotos(ids: [String]) async throws
}
