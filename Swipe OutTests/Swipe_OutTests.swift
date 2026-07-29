//
//  Swipe_OutTests.swift
//  Swipe OutTests
//
//  Created by Omar Regalado Mendoza on 20/07/26.
//

import Testing
import Foundation
@testable import Swipe_Out

@MainActor
struct ReviewViewModelTests {

    //MARK: - Helper
    private func makeSUT(mock: MockPhotoLibraryService) async -> ReviewViewModel {
        let sut = ReviewViewModel(library: mock)
        await sut.requestAccess()
        return sut
    }

    //MARK: - Tests Functions
    /// Main function, delete ONLY selected photos
    @Test func deletes_exactly_the_marked_photos() async {
        let mock = MockPhotoLibraryService(photos: [
            PhotoItem(id: "a"),
            PhotoItem(id: "b"),
            PhotoItem(id: "c"),
            PhotoItem(id: "d"),
        ])
        let sut = await makeSUT(mock: mock)

        await sut.handleDecision(delete: true)
        await sut.handleDecision(delete: false)
        await sut.handleDecision(delete: true)

        let outcome = await sut.deleteMarkedPhotos()
        #expect(outcome == .success)
        let deleted = await mock.deletedIDs
        #expect(deleted == ["a", "c"])
    }

    @Test func multilevel_undo_keeps_counts_in_sync() async {
        let mock = MockPhotoLibraryService(
            photos: [
                PhotoItem(id: "a"),
                PhotoItem(id: "b"),
                PhotoItem(id: "c"),
            ],
            sizes: ["a": 100, "b": 200, "c": 300]
        )
        let sut = await makeSUT(mock: mock)

        await sut.handleDecision(delete: true)
        await sut.handleDecision(delete: true)
        #expect(sut.toDeleteCount == 2)
        #expect(sut.bytesToDelete == 300)

        sut.undo()
        #expect(sut.toDeleteCount == 1)
        #expect(sut.bytesToDelete == 100)

        sut.undo()
        #expect(sut.toDeleteCount == 0)
        #expect(sut.bytesToDelete == 0)
        #expect(sut.canUndo == false)
    }

    @Test func undoing_a_keep_does_not_affect_delete_list() async {
        let mock = MockPhotoLibraryService(photos: [
            PhotoItem(id: "a"),
            PhotoItem(id: "b"),
        ])
        let sut = await makeSUT(mock: mock)

        await sut.handleDecision(delete: false)
        #expect(sut.currentIndex == 1)
        #expect(sut.toDeleteCount == 0)

        sut.undo()
        #expect(sut.currentIndex == 0)
        #expect(sut.toDeleteCount == 0)
    }

    @Test func empty_gallery_finishes_immediately() async {
        let mock = MockPhotoLibraryService(photos: [])
        let sut = await makeSUT(mock: mock)

        #expect(sut.total == 0)
        #expect(sut.isFinished == true)
        #expect(sut.canUndo == false)
    }

    @Test func denied_access_sets_denied_state() async {
        let sut = ReviewViewModel(library: MockPhotoLibraryService(access: .denied))
        await sut.requestAccess()
        #expect(sut.authState == .denied)
    }

    @Test func failed_deletion_keeps_marks() async {
        let mock = MockPhotoLibraryService(
            photos: [PhotoItem(id: "a")],
            deletionError: .failed
        )
        let sut = await makeSUT(mock: mock)
        await sut.handleDecision(delete: true)

        let outcome = await sut.deleteMarkedPhotos()
        #expect(outcome == .failed)
        #expect(sut.toDeleteCount == 1)
    }

    @Test func cancelled_deletion_keeps_marks() async {
        let mock = MockPhotoLibraryService(
            photos: [PhotoItem(id: "a")],
            deletionError: .cancelled
        )
        let sut = await makeSUT(mock: mock)
        await sut.handleDecision(delete: true)

        let outcome = await sut.deleteMarkedPhotos()
        #expect(outcome == .cancelled)
        #expect(sut.toDeleteCount == 1)
    }

    @Test func limited_access_is_authorized_and_flagged() async {
        let mock = MockPhotoLibraryService(access: .limited,
                                           photos: [PhotoItem(id: "a")])
        let sut = await makeSUT(mock: mock)
        #expect(sut.authState == .authorized)
        #expect(sut.isLimitedAccess == true)
    }
}
