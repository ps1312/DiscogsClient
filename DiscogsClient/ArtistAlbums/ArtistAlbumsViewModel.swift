import Foundation
import Combine

@MainActor
final class ArtistAlbumsViewModel: ObservableObject {
    @Published private(set) var isFirstLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var paginationErrorMessage: String?
    @Published private(set) var paginated = Paginated<ArtistRelease>(
        items: [],
        currentPage: 0,
        totalPages: 0
    )

    let artistID: Int

    private let client: HTTPClient

    var albums: [ArtistRelease] {
        paginated.items
    }

    var currentPage: Int {
        paginated.currentPage
    }

    var totalPages: Int {
        paginated.totalPages
    }

    init(client: HTTPClient, artistID: Int) {
        self.client = client
        self.artistID = artistID
    }

    func fetchAlbums() async {
        paginated = Paginated(items: [], currentPage: 0, totalPages: 0)
        isFirstLoading = true
        isLoadingMore = false
        errorMessage = nil
        paginationErrorMessage = nil

        await loadPage(page: 1, appending: false)
    }

    func loadNextPage() async {
        guard !isFirstLoading, !isLoadingMore else { return }
        guard paginated.currentPage < paginated.totalPages else { return }

        isLoadingMore = true
        errorMessage = nil
        paginationErrorMessage = nil

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

            let mergedAlbums = Self.mergeAlbums(existing: paginated.items, incoming: page.items)
                .sorted(by: Self.albumSort)
            paginationErrorMessage = nil
            
            paginated = Paginated(
                items: mergedAlbums,
                currentPage: page.currentPage,
                totalPages: page.totalPages
            )
        } catch {
            if requestedPage > 1, !paginated.items.isEmpty {
                errorMessage = nil
                paginationErrorMessage = "Couldn't load more results. Please try again later."
            } else {
                errorMessage = "Failed to load albums. Please try again later."
                paginationErrorMessage = nil
            }
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
