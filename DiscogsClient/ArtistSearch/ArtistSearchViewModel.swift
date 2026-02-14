import Foundation
import Combine

@MainActor
final class ArtistSearchViewModel: ObservableObject {
    @Published var searchText = ""
    
    @Published private(set) var results: [Artist] = []
    @Published private(set) var isFirstLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var hasSearched = false

    private let client: HTTPClient
    private var currentQuery: String = ""
    private var currentPage = 0
    private var totalPages = 0

    init(client: HTTPClient) {
        self.client = client
    }

    func searchDebounced(query: String) async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            setSearchIsEmpty()
            return
        }

        setSearchStarted(with: query)

        do {
            try await Task.sleep(nanoseconds: 500_000_000)
        } catch {
            return
        }

        await loadPage(query: trimmedQuery, page: 1, appending: false)
    }

    func loadNextPage() async {
        guard !isFirstLoading, !isLoadingMore else { return }
        guard currentPage < totalPages else { return }

        isFirstLoading = false
        isLoadingMore = true
        errorMessage = nil
        
        let nextPage = currentPage + 1
        await loadPage(query: currentQuery, page: nextPage, appending: true)
    }
    
    private func setSearchIsEmpty() {
        hasSearched = false
        results = []
        errorMessage = nil
        isFirstLoading = false
        isLoadingMore = false
        currentQuery = ""
        resetPagination()
    }
    
    private func setSearchStarted(with query: String) {
        results = []
        errorMessage = nil
        isFirstLoading = true
        isLoadingMore = false
        currentQuery = query
        resetPagination()
    }

    private func resetPagination() {
        currentPage = 0
        totalPages = 0
    }

    private func loadPage(query: String, page requestedPage: Int, appending: Bool) async {
        do {
            let request = ApiRequestBuilder.search(query: query, page: requestedPage)
            let (data, response) = try await client.send(request)
            let page = try ArtistSearchMapper.map(data, response)

            guard page.page == requestedPage else {
                isFirstLoading = false
                isLoadingMore = false
                return
            }

            currentPage = page.page
            totalPages = page.pages
            results.append(contentsOf: page.artists)
            isFirstLoading = false
            isLoadingMore = false
        } catch {
            isFirstLoading = false
            isLoadingMore = false
            errorMessage = error.localizedDescription
        }
    }
}
