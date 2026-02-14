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
                    results: [SearchResultFixture(id: 1, title: "ABBA", thumb: nil)]
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
    }

    @MainActor
    func test_searchDebounced_loadsFirstPageAndUpdatesState() async throws {
        let client = FakeHTTPClient()
        client.responses = [
            .success(
                data: makeSearchPayload(
                    page: 1,
                    pages: 2,
                    results: [SearchResultFixture(id: 101, title: "Metallica", thumb: nil)]
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
                    results: [SearchResultFixture(id: 1, title: "ABBA", thumb: nil)]
                ),
                statusCode: 200
            ),
            .success(
                data: makeSearchPayload(
                    page: 2,
                    pages: 2,
                    results: [SearchResultFixture(id: 2, title: "A-Teens", thumb: nil)]
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
                    results: [SearchResultFixture(id: 1, title: "ABBA", thumb: nil)]
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
                    results: [SearchResultFixture(id: 1, title: "ABBA", thumb: nil)]
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

private final class FakeHTTPClient: HTTPClient {
    enum Response {
        case success(data: Data, statusCode: Int)
        case failure(Error)
    }

    var responses: [Response] = []
    private(set) var requests: [URLRequest] = []

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)

        guard !responses.isEmpty else {
            throw NSError(
                domain: "FakeHTTPClient",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No stubbed response available"]
            )
        }

        let response = responses.removeFirst()
        switch response {
        case let .success(data, statusCode):
            let url = request.url ?? URL(string: "https://api.discogs.com")!
            let httpResponse = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (data, httpResponse)
        case let .failure(error):
            throw error
        }
    }
}

private struct SearchResultFixture {
    let id: Int
    let title: String
    let thumb: String?
}

private func makeSearchPayload(page: Int, pages: Int, results: [SearchResultFixture]) -> Data {
    struct Pagination: Encodable {
        let page: Int
        let pages: Int
        let per_page: Int
        let items: Int
    }

    struct SearchResult: Encodable {
        let id: Int
        let title: String
        let type: String
        let thumb: String?
    }

    struct Payload: Encodable {
        let pagination: Pagination
        let results: [SearchResult]
    }

    let payload = Payload(
        pagination: Pagination(page: page, pages: pages, per_page: 30, items: results.count),
        results: results.map {
            SearchResult(id: $0.id, title: $0.title, type: "artist", thumb: $0.thumb)
        }
    )

    return try! JSONEncoder().encode(payload)
}

private func queryValue(named name: String, in request: URLRequest) -> String? {
    guard
        let url = request.url,
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    else {
        return nil
    }

    return components.queryItems?.first(where: { $0.name == name })?.value
}
