//
//  MockPhotoLibraryService.swift
//  Swipe Out
//
//  Created by Omar Regalado Mendoza on 28/07/26.
//

import UIKit
@testable import Swipe_Out

actor MockPhotoLibraryService: PhotoLibraryService {
    
    var access: PhotoAccess
    var photos: [PhotoItem]
    var deletionError: PhotoLibraryError?
    private(set) var deletedIDs: [String] = []

    init(access: PhotoAccess = .granted, photos: [PhotoItem] = [], deletionError: PhotoLibraryError? = nil) {
            self.access = access
            self.photos = photos
            self.deletionError = deletionError
        }

    func requestAuthorization() async -> PhotoAccess { access }

    func fetchPhotos() async -> [PhotoItem] { photos }

    func loadImage(id: String, targetSize: CGSize) async -> UIImage? { nil }

    func deletePhotos(ids: [String]) async throws {
        if let deletionError { throw deletionError }
        deletedIDs.append(contentsOf: ids)
        photos.removeAll { ids.contains($0.id) }
    }
}
