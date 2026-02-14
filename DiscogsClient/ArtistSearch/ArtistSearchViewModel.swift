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
    @Published private(set) var hasSearched = false

    private let client: HTTPClient
    private var currentQuery: String = ""

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

        await loadPage(query: trimmedQuery, page: 1)
    }

    func loadNextPage() async {
        guard !isFirstLoading, !isLoadingMore else { return }
        guard paginated.currentPage < paginated.totalPages else { return }

        isFirstLoading = false
        isLoadingMore = true
        errorMessage = nil
        
        let nextPage = paginated.currentPage + 1
        await loadPage(query: currentQuery, page: nextPage)
    }
    
    private func setSearchIsEmpty() {
        hasSearched = false
        paginated = Paginated(items: [], currentPage: 0, totalPages: 0)
        errorMessage = nil
        isFirstLoading = false
        isLoadingMore = false
        currentQuery = ""
    }
    
    private func setSearchStarted(with query: String) {
        hasSearched = true
        paginated = Paginated(items: [], currentPage: 0, totalPages: 0)
        errorMessage = nil
        isFirstLoading = true
        isLoadingMore = false
        currentQuery = query
    }

    private func loadPage(query: String, page requestedPage: Int) async {
        do {
            let request = ApiRequestBuilder.search(query: query, page: requestedPage)
            let (data, response) = try await client.send(request)
            let page = try ArtistSearchMapper.map(data, response)

            isFirstLoading = false
            isLoadingMore = false
            paginated = Paginated(
                items: paginated.items + page.items,
                currentPage: page.currentPage,
                totalPages: page.totalPages
            )
        } catch {
            isFirstLoading = false
            isLoadingMore = false
            errorMessage = error.localizedDescription
        }
    }
}
