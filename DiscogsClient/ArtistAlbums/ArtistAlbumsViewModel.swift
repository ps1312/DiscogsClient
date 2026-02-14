import Foundation
import Combine

@MainActor
final class ArtistAlbumsViewModel: ObservableObject {
    @Published private(set) var albums: [ArtistRelease] = []
    @Published private(set) var isFirstLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var errorMessage: String?

    let artistID: Int

    private let client: HTTPClient
    private var currentPage = 0
    private var totalPages = 0

    init(client: HTTPClient, artistID: Int) {
        self.client = client
        self.artistID = artistID
    }

    func fetchAlbums() async {
        albums = []
        currentPage = 0
        totalPages = 0
        isFirstLoading = true
        isLoadingMore = false
        errorMessage = nil

        await loadPage(page: 1, appending: false)
    }

    func loadNextPage() async {
        guard !isFirstLoading, !isLoadingMore else { return }
        guard currentPage < totalPages else { return }

        isLoadingMore = true
        errorMessage = nil

        await loadPage(page: currentPage + 1, appending: true)
    }

    private func loadPage(page requestedPage: Int, appending: Bool) async {
        defer {
            isFirstLoading = false
            isLoadingMore = false
        }

        do {
            let request = ApiRequestBuilder.artistReleases(for: artistID, page: requestedPage)
            let (data, response) = try await client.send(request)
            let page = try ArtistAlbumsMapper.map(data, response)

            guard page.page == requestedPage else { return }

            currentPage = page.page
            totalPages = page.pages

            albums = Self.mergeAlbums(existing: albums, incoming: page.albums)
            albums.sort(by: Self.albumSort)
        } catch {
            errorMessage = "Failed to load albums: \(error.localizedDescription)"
        }
    }

    private static func mergeAlbums(existing: [ArtistRelease], incoming: [ArtistRelease]) -> [ArtistRelease] {
        var mergedByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })

        for release in incoming {
            guard let current = mergedByID[release.id] else {
                mergedByID[release.id] = release
                continue
            }

            mergedByID[release.id] = ArtistRelease(
                id: current.id,
                title: release.title,
                year: release.year ?? current.year,
                thumb: release.thumb ?? current.thumb,
                format: release.format ?? current.format,
                type: release.type ?? current.type,
                label: release.label ?? current.label
            )
        }

        return Array(mergedByID.values)
    }

    private static func albumSort(lhs: ArtistRelease, rhs: ArtistRelease) -> Bool {
        let lhsYear = lhs.year ?? Int.min
        let rhsYear = rhs.year ?? Int.min

        if lhsYear != rhsYear {
            return lhsYear > rhsYear
        }

        let titleOrder = lhs.title.localizedCaseInsensitiveCompare(rhs.title)
        if titleOrder != .orderedSame {
            return titleOrder == .orderedAscending
        }

        return lhs.id < rhs.id
    }
}
