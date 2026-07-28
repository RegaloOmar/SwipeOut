//
//  PhotoLibraryService.swift
//  Swipe Out
//
//  Created by Omar Regalado Mendoza on 28/07/26.
//

import UIKit

enum PhotoAccess {
    case full
    case limited
    case denied
}

enum PhotoLibraryError: Error {
    case cancelled
    case failed
}

protocol PhotoLibraryService: Sendable {
    func requestAuthorization() async -> PhotoAccess
    func fetchPhotos() async -> [PhotoItem]
    func loadImage(id: String, targetSize: CGSize) async -> UIImage?
    func deletePhotos(ids: [String]) async throws
    func presentLimitedPicker() async
}
