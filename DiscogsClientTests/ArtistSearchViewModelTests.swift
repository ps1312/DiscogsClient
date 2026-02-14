import XCTest
@testable import DiscogsClient

final class ArtistSearchViewModelTests: XCTestCase {
    @MainActor
    func test_searchDebounced_emptyQuery_resetsStateAndDoesNotCallClient() async {
        let client = FakeHTTPClient()
        client.responses = [
            .success(
                data: makeSearchPayload(
                    page: 1,
                    pages: 1,
                    results: [(id: 1, title: "ABBA", thumb: nil)]
                ),
                statusCode: 200
            )
        ]
        let sut = ArtistSearchViewModel(client: client)

        await sut.searchDebounced(query: "ABBA")
        XCTAssertEqual(client.requests.count, 1)

        await sut.searchDebounced(query: "   ")

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertTrue(sut.paginated.items.isEmpty)
        XCTAssertFalse(sut.hasSearched)
        XCTAssertFalse(sut.isFirstLoading)
        XCTAssertFalse(sut.isLoadingMore)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.paginated.currentPage, 0)
        XCTAssertEqual(sut.paginated.totalPages, 0)
        XCTAssertEqual(sut.emptyStateTitle, "Start Searching")
        XCTAssertEqual(sut.emptyStateMessage, "Find artists on Discogs")
    }

    @MainActor
    func test_searchDebounced_loadsFirstPageAndUpdatesState() async throws {
        let client = FakeHTTPClient()
        client.responses = [
            .success(
                data: makeSearchPayload(
                    page: 1,
                    pages: 2,
                    results: [(id: 101, title: "Metallica", thumb: nil)]
                ),
                statusCode: 200
            )
        ]
        let sut = ArtistSearchViewModel(client: client)

        await sut.searchDebounced(query: "  Metallica  ")

        XCTAssertEqual(sut.paginated.items.map(\.id), [101])
        XCTAssertEqual(sut.paginated.items.first?.title, "Metallica")
        XCTAssertTrue(sut.hasSearched)
        XCTAssertFalse(sut.isFirstLoading)
        XCTAssertFalse(sut.isLoadingMore)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.paginated.currentPage, 1)
        XCTAssertEqual(sut.paginated.totalPages, 2)
        XCTAssertEqual(client.requests.count, 1)
        
        let firstRequest = try XCTUnwrap(client.requests.first)
        XCTAssertEqual(queryValue(named: "q", in: firstRequest), "Metallica")
        XCTAssertEqual(queryValue(named: "page", in: firstRequest), "1")
    }

    @MainActor
    func test_loadNextPage_appendsArtists() async throws {
        let client = FakeHTTPClient()
        client.responses = [
            .success(
                data: makeSearchPayload(
                    page: 1,
                    pages: 2,
                    results: [(id: 1, title: "ABBA", thumb: nil)]
                ),
                statusCode: 200
            ),
            .success(
                data: makeSearchPayload(
                    page: 2,
                    pages: 2,
                    results: [(id: 2, title: "A-Teens", thumb: nil)]
                ),
                statusCode: 200
            )
        ]
        let sut = ArtistSearchViewModel(client: client)

        await sut.searchDebounced(query: "ABBA")
        await sut.loadNextPage()

        XCTAssertEqual(sut.paginated.items.map(\.id), [1, 2])
        XCTAssertEqual(sut.paginated.items.map(\.title), ["ABBA", "A-Teens"])
        XCTAssertEqual(sut.paginated.items.first?.id, 1)
        XCTAssertEqual(sut.paginated.items.last?.id, 2)
        XCTAssertEqual(sut.paginated.currentPage, 2)
        XCTAssertEqual(sut.paginated.totalPages, 2)
        XCTAssertEqual(client.requests.count, 2)

        let secondRequest = try XCTUnwrap(client.requests.last)
        XCTAssertEqual(queryValue(named: "page", in: secondRequest), "2")
        XCTAssertFalse(sut.isLoadingMore)
        XCTAssertNil(sut.errorMessage)
    }

    @MainActor
    func test_loadNextPage_whenNoMorePages_doesNothing() async {
        let client = FakeHTTPClient()
        client.responses = [
            .success(
                data: makeSearchPayload(
                    page: 1,
                    pages: 1,
                    results: [(id: 1, title: "ABBA", thumb: nil)]
                ),
                statusCode: 200
            )
        ]
        let sut = ArtistSearchViewModel(client: client)

        await sut.searchDebounced(query: "ABBA")
        await sut.loadNextPage()

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(sut.paginated.items.map(\.id), [1])
        XCTAssertFalse(sut.isLoadingMore)
    }

    @MainActor
    func test_searchDebounced_failure_setsError() async {
        let client = FakeHTTPClient()
        client.responses = [
            .failure(
                NSError(
                    domain: "ArtistSearchViewModelTests",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "network failed"]
                )
            )
        ]
        let sut = ArtistSearchViewModel(client: client)

        await sut.searchDebounced(query: "ABBA")

        XCTAssertTrue(sut.paginated.items.isEmpty)
        XCTAssertTrue(sut.hasSearched)
        XCTAssertFalse(sut.isFirstLoading)
        XCTAssertFalse(sut.isLoadingMore)
        XCTAssertEqual(sut.errorMessage, "network failed")
    }

    @MainActor
    func test_loadNextPage_failure_keepsExistingResultsAndSetsError() async {
        let client = FakeHTTPClient()
        client.responses = [
            .success(
                data: makeSearchPayload(
                    page: 1,
                    pages: 2,
                    results: [(id: 1, title: "ABBA", thumb: nil)]
                ),
                statusCode: 200
            ),
            .failure(
                NSError(
                    domain: "ArtistSearchViewModelTests",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "next page failed"]
                )
            )
        ]
        let sut = ArtistSearchViewModel(client: client)

        await sut.searchDebounced(query: "ABBA")
        await sut.loadNextPage()

        XCTAssertEqual(sut.paginated.items.map(\.id), [1])
        XCTAssertFalse(sut.isLoadingMore)
        XCTAssertEqual(sut.errorMessage, "next page failed")
    }

    @MainActor
    func test_emptyState_whenSearchedAndNoResults_showsNoResultsMessage() async {
        let client = FakeHTTPClient()
        client.responses = [
            .success(
                data: makeSearchPayload(
                    page: 1,
                    pages: 1,
                    results: []
                ),
                statusCode: 200
            )
        ]
        let sut = ArtistSearchViewModel(client: client)
        sut.searchText = "Unknown Artist"

        await sut.searchDebounced(query: sut.searchText)

        XCTAssertEqual(sut.emptyStateTitle, "No Results")
        XCTAssertEqual(sut.emptyStateMessage, "No matches found for \"Unknown Artist\"")
    }

}

private struct UnusedHTTPClient: HTTPClient {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        throw NSError(
            domain: "UnusedHTTPClient",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "Unused in this test"]
        )
    }
}

private func makeSearchPayload(
    page: Int,
    pages: Int,
    results: [(id: Int, title: String, thumb: String?)]
) -> Data {
    let resultObjects: [[String: Any]] = results.map { result in
        var object: [String: Any] = [
            "id": result.id,
            "title": result.title,
            "type": "artist"
        ]
        if let thumb = result.thumb {
            object["thumb"] = thumb
        }
        return object
    }

    let payload: [String: Any] = [
        "pagination": [
            "page": page,
            "pages": pages,
            "per_page": 30,
            "items": results.count
        ],
        "results": resultObjects
    ]

    return try! JSONSerialization.data(withJSONObject: payload)
}
