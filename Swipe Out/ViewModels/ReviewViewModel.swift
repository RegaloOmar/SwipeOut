//
//  ReviewViewModel.swift
//  Swipe Out
//
//  Created by Omar Regalado Mendoza on 28/07/26.
//

import SwiftUI

@MainActor
@Observable
final class ReviewViewModel {

    enum AuthState { case unknown, authorized, denied }
    enum DeletionOutcome { case success, cancelled, failed }

    // MARK: - Dependencies
    private let library: PhotoLibraryService
    private let imageLoader: ImageLoader

    // MARK: - State
    var authState: AuthState = .unknown
    private var items: [PhotoItem] = []
    var currentIndex = 0
    var currentImage: UIImage?
    var isLimitedAccess = false

    var total: Int { items.count }
    var isFinished: Bool { currentIndex >= items.count }

    // MARK: - Decisions Vars
    private(set) var toDelete: [PhotoItem] = []
    private var decisionHistory: [Bool] = []
    var toDeleteCount: Int { toDelete.count }
    var canUndo: Bool { !decisionHistory.isEmpty }

    /// Tamaños ya consultados, por id. Se llena bajo demanda al marcar.
    private var sizeByID: [String: Int64] = [:]

    /// Suma de tamaños de las fotos actualmente marcadas. Calculada → nunca se desincroniza.
    var bytesToDelete: Int64 {
        toDelete.reduce(0) { $0 + (sizeByID[$1.id] ?? 0) }
    }
    var freedSpaceText: String { bytesToDelete.formatted(.byteCount(style: .file)) }


    init(library: PhotoLibraryService) {
        self.library = library
        self.imageLoader = ImageLoader(library: library)
    }

    // MARK: - Funcitons
    func requestAccess() async {
        switch await library.requestAuthorization() {
        case .full:
            isLimitedAccess = false
            await loadPhotos()
            authState = .authorized
        case .limited:
            isLimitedAccess = true
            await loadPhotos()
            authState = .authorized
        case .denied:
            authState = .denied
        }
    }

    private func loadPhotos() async {
        items = await library.fetchPhotos()
        currentIndex = 0
        showCurrentImage()
    }

    /// Function to know if is safe to refetch the photos
    /// runs after the app comes to being active again
    func refreshOnForeground() async {
        guard authState == .authorized, toDelete.isEmpty else { return }
        let fresh = await library.fetchPhotos()
        guard fresh.map(\.id) != items.map(\.id) else { return }   // nada cambió
        items = fresh
        currentIndex = 0
        showCurrentImage()
    }

    // MARK: - Decisions
    func handleDecision(delete: Bool) async {
        guard currentIndex < items.count else { return }
        let item = items[currentIndex]

        // Avanzamos de inmediato (UI ágil) dentro de la animación.
        withAnimation(.smooth(duration: 0.3)) {
            if delete { toDelete.append(item) }
            decisionHistory.append(delete)
            currentIndex += 1
        }
        showCurrentImage()

        // Solo si se marcó para borrar, pedimos su tamaño (una consulta, no 10.000).
        if delete, sizeByID[item.id] == nil {
            sizeByID[item.id] = await library.fileSize(for: item.id)
        }
    }

    func undo() {
        guard let wasDelete = decisionHistory.popLast() else { return }
        currentIndex -= 1
        if wasDelete {
            toDelete.removeLast()      // bytesToDelete se recalcula solo (excluye lo quitado)
        }
        showCurrentImage()
    }

    private func showCurrentImage() {
        guard currentIndex < items.count else {
            currentImage = nil
            return
        }
        let index = currentIndex
        let id = items[index].id

        if let cached = imageLoader.cachedImage(for: id) {
            currentImage = cached
        } else {
            Task {
                let image = await imageLoader.image(for: id)
                guard currentIndex == index else { return }
                currentImage = image
            }
        }

        preloadNeighbors(around: index)
        pruneCache(around: index)
    }

    private func preloadNeighbors(around index: Int) {
        var ids: [String] = []
        if items.indices.contains(index + 1) { ids.append(items[index + 1].id) }
        if items.indices.contains(index - 1) { ids.append(items[index - 1].id) }
        imageLoader.preload(ids)
    }

    private func pruneCache(around index: Int) {
        let keep = (index - 3...index + 3).compactMap {
            items.indices.contains($0) ? items[$0].id : nil
        }
        imageLoader.keepOnly(keep)
    }

    func deleteMarkedPhotos() async -> DeletionOutcome {
            guard !toDelete.isEmpty else { return .success }
            do {
                try await library.deletePhotos(ids: toDelete.map(\.id))
                toDelete.removeAll()
                decisionHistory.removeAll()
                sizeByID.removeAll()
                return .success
            } catch PhotoLibraryError.cancelled {
                return .cancelled
            } catch {
                return .failed
            }
        }

    func restart() {
        toDelete.removeAll()
        decisionHistory.removeAll()
        sizeByID.removeAll()
        imageLoader.keepOnly([])
        Task { await loadPhotos() }
    }
    
    func expandLimitedSelection() async {
        await library.presentLimitedPicker()
        await loadPhotos()
    }
}
