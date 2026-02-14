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
        XCTAssertTrue(sut.results.isEmpty)
        XCTAssertFalse(sut.hasSearched)
        XCTAssertFalse(sut.isFirstLoading)
        XCTAssertFalse(sut.isLoadingMore)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.currentPage, 0)
        XCTAssertEqual(sut.totalPages, 0)
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

        XCTAssertEqual(sut.results.map(\.id), [101])
        XCTAssertEqual(sut.results.first?.title, "Metallica")
        XCTAssertTrue(sut.hasSearched)
        XCTAssertFalse(sut.isFirstLoading)
        XCTAssertFalse(sut.isLoadingMore)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.currentPage, 1)
        XCTAssertEqual(sut.totalPages, 2)
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

        XCTAssertEqual(sut.results.map(\.id), [1, 2])
        XCTAssertEqual(sut.results.map(\.title), ["ABBA", "A-Teens"])
        XCTAssertEqual(sut.results.first?.id, 1)
        XCTAssertEqual(sut.results.last?.id, 2)
        XCTAssertEqual(sut.currentPage, 2)
        XCTAssertEqual(sut.totalPages, 2)
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
        XCTAssertEqual(sut.results.map(\.id), [1])
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

        XCTAssertTrue(sut.results.isEmpty)
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

        XCTAssertEqual(sut.results.map(\.id), [1])
        XCTAssertFalse(sut.isLoadingMore)
        XCTAssertEqual(sut.errorMessage, "next page failed")
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
