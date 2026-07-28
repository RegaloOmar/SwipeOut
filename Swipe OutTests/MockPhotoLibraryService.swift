//
//  MockPhotoLibraryService.swift
//  Swipe Out
//
//  Created by Omar Regalado Mendoza on 28/07/26.
//

import UIKit
@testable import Swipe_Out

/// Fototeca falsa, en memoria. Sin PhotoKit, sin permisos, 100% controlable.
actor MockPhotoLibraryService: PhotoLibraryService {
    var access: PhotoAccess
    var photos: [PhotoItem]
    var shouldFailDeletion: Bool
    private(set) var deletedIDs: [String] = []

    init(access: PhotoAccess = .granted,
         photos: [PhotoItem] = [],
         shouldFailDeletion: Bool = false) {
        self.access = access
        self.photos = photos
        self.shouldFailDeletion = shouldFailDeletion
    }

    func requestAuthorization() async -> PhotoAccess { access }

    func fetchPhotos() async -> [PhotoItem] { photos }

    func loadImage(id: String, targetSize: CGSize) async -> UIImage? { nil } // irrelevante para la lógica

    func deletePhotos(ids: [String]) async throws {
        if shouldFailDeletion { throw PhotoLibraryError.deletionFailed }
        deletedIDs.append(contentsOf: ids)
        photos.removeAll { ids.contains($0.id) }
    }
}
