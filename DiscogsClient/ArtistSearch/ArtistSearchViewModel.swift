import Foundation
import Combine

@MainActor
final class ArtistSearchViewModel: ObservableObject {
    @Published var searchText = ""

    @Published private(set) var isFirstLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var paginated = Paginated<Artist>(
        items: [],
        currentPage: 0,
        totalPages: 0
    )
    @Published private(set) var errorMessage: String?
    @Published private(set) var paginationErrorMessage: String?
    @Published private(set) var hasSearched = false

    private let client: HTTPClient
    private var currentQuery: String = ""

    var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(client: HTTPClient) {
        self.client = client
    }

    func searchDebounced(query: String) async {
        searchText = query
        let trimmedQuery = trimmedSearchText

        guard !trimmedQuery.isEmpty else {
            setSearchIsEmpty()
            return
        }

        setSearchStarted(with: trimmedQuery)

        do {
            try await Task.sleep(nanoseconds: 500_000_000)
        } catch {
            return
        }

        await loadPage(query: trimmedQuery, page: 1)
    }

    func loadNextPage() async {
        guard !isFirstLoading, !isLoadingMore else { return }
        guard paginated.currentPage < paginated.totalPages else { return }

        isFirstLoading = false
        isLoadingMore = true
        errorMessage = nil
        paginationErrorMessage = nil

        let nextPage = paginated.currentPage + 1
        await loadPage(query: currentQuery, page: nextPage)
    }

    private func setSearchIsEmpty() {
        hasSearched = false
        paginated = Paginated(items: [], currentPage: 0, totalPages: 0)
        errorMessage = nil
        paginationErrorMessage = nil
        isFirstLoading = false
        isLoadingMore = false
        currentQuery = ""
    }

    private func setSearchStarted(with committedQuery: String) {
        hasSearched = true
        paginated = Paginated(items: [], currentPage: 0, totalPages: 0)
        errorMessage = nil
        paginationErrorMessage = nil
        isFirstLoading = true
        isLoadingMore = false
        currentQuery = committedQuery
    }

    private func loadPage(query: String, page requestedPage: Int) async {
        do {
            let request = ApiRequestBuilder.search(query: query, page: requestedPage)
            let (data, response) = try await client.send(request)
            let page = try ArtistSearchMapper.map(data, response)

            isFirstLoading = false
            isLoadingMore = false
            paginationErrorMessage = nil
            paginated = Paginated(
                items: paginated.items + page.items,
                currentPage: page.currentPage,
                totalPages: page.totalPages
            )
        } catch {
            if Self.isCancellation(error) {
                return
            }

            isFirstLoading = false
            isLoadingMore = false

            if requestedPage > 1, !paginated.items.isEmpty {
                errorMessage = nil
                paginationErrorMessage = "Couldn't load more results. Please try again later."
            } else {
                errorMessage = "Error loading search results. Please try again later."
                paginationErrorMessage = nil
            }
        }
    }

    private static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError {
            return true
        }

        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
    }
}
