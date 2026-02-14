import XCTest
@testable import DiscogsClient

final class ArtistAlbumsViewModelTests: XCTestCase {
    @MainActor
    func test_fetchAlbums_loadsFirstPage() async {
        let client = FakeHTTPClient()
        client.responses = [
            .success(
                data: makeAlbumsPayload(
                    page: 1,
                    pages: 2,
                    releases: [
                        (id: 1, title: "Album One", year: 1999, format: "Album", type: "release", label: "Label A")
                    ]
                ),
                statusCode: 200
            )
        ]

        let sut = ArtistAlbumsViewModel(client: client, artistID: 77)

        await sut.fetchAlbums()

        XCTAssertEqual(sut.albums.map(\.id), [1])
        XCTAssertFalse(sut.isFirstLoading)
        XCTAssertFalse(sut.isLoadingMore)
        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.paginationErrorMessage)
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(queryValue(named: "page", in: client.requests[0]), "1")
    }

    @MainActor
    func test_loadNextPage_appendsAlbums() async {
        let client = FakeHTTPClient()
        client.responses = [
            .success(
                data: makeAlbumsPayload(
                    page: 1,
                    pages: 2,
                    releases: [
                        (id: 1, title: "Album One", year: 1999, format: "Album", type: "release", label: "Label A")
                    ]
                ),
                statusCode: 200
            ),
            .success(
                data: makeAlbumsPayload(
                    page: 2,
                    pages: 2,
                    releases: [
                        (id: 2, title: "Album Two", year: 2001, format: "Album", type: "release", label: "Label B")
                    ]
                ),
                statusCode: 200
            )
        ]

        let sut = ArtistAlbumsViewModel(client: client, artistID: 77)

        await sut.fetchAlbums()
        await sut.loadNextPage()

        XCTAssertEqual(sut.albums.map(\.id), [2, 1])
        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(queryValue(named: "page", in: client.requests[1]), "2")
        XCTAssertFalse(sut.isLoadingMore)
        XCTAssertNil(sut.paginationErrorMessage)
    }

    @MainActor
    func test_loadNextPage_reordersAlbumsAfterMergingNewData() async {
        let client = FakeHTTPClient()
        client.responses = [
            .success(
                data: makeAlbumsPayload(
                    page: 1,
                    pages: 2,
                    releases: [
                        (id: 10, title: "Beta Album", year: 1998, format: "Album", type: "release", label: "Label A"),
                        (id: 11, title: "Alpha Album", year: 1998, format: "Album", type: "release", label: "Label A")
                    ]
                ),
                statusCode: 200
            ),
            .success(
                data: makeAlbumsPayload(
                    page: 2,
                    pages: 2,
                    releases: [
                        (id: 12, title: "Newest Album", year: 2005, format: "Album", type: "release", label: "Label B")
                    ]
                ),
                statusCode: 200
            )
        ]

        let sut = ArtistAlbumsViewModel(client: client, artistID: 77)

        await sut.fetchAlbums()
        XCTAssertEqual(sut.albums.map(\.id), [11, 10])

        await sut.loadNextPage()

        XCTAssertEqual(sut.albums.map(\.id), [12, 11, 10])
    }

    @MainActor
    func test_loadNextPage_duplicateReleaseID_mergesIntoSingleAlbum() async {
        let client = FakeHTTPClient()
        client.responses = [
            .success(
                data: makeAlbumsPayload(
                    page: 1,
                    pages: 2,
                    releases: [
                        (id: 1484452, title: "Musical Mastication Volume 4", year: nil, format: nil, type: "master", label: nil)
                    ]
                ),
                statusCode: 200
            ),
            .success(
                data: makeAlbumsPayload(
                    page: 2,
                    pages: 2,
                    releases: [
                        (id: 1484452, title: "Musical Mastication Volume 4", year: 2018, format: nil, type: "master", label: "Discogs Label")
                    ]
                ),
                statusCode: 200
            )
        ]

        let sut = ArtistAlbumsViewModel(client: client, artistID: 77)

        await sut.fetchAlbums()
        await sut.loadNextPage()

        XCTAssertEqual(sut.albums.count, 1)
        XCTAssertEqual(sut.albums.map(\.id), [1484452])
        XCTAssertEqual(sut.albums.first?.year, 2018)
        XCTAssertEqual(sut.albums.first?.label, "Discogs Label")
        XCTAssertEqual(client.requests.count, 2)
    }

    @MainActor
    func test_loadNextPage_whenNoMorePages_doesNothing() async {
        let client = FakeHTTPClient()
        client.responses = [
            .success(
                data: makeAlbumsPayload(
                    page: 1,
                    pages: 1,
                    releases: [
                        (id: 1, title: "Album One", year: 1999, format: "Album", type: "release", label: "Label A")
                    ]
                ),
                statusCode: 200
            )
        ]

        let sut = ArtistAlbumsViewModel(client: client, artistID: 77)

        await sut.fetchAlbums()
        await sut.loadNextPage()

        XCTAssertEqual(sut.albums.map(\.id), [1])
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertFalse(sut.isLoadingMore)
    }

    @MainActor
    func test_loadNextPage_failure_keepsExistingAlbumsAndSetsPaginationError() async {
        let client = FakeHTTPClient()
        client.responses = [
            .success(
                data: makeAlbumsPayload(
                    page: 1,
                    pages: 2,
                    releases: [
                        (id: 1, title: "Album One", year: 1999, format: "Album", type: "release", label: "Label A")
                    ]
                ),
                statusCode: 200
            ),
            .failure(
                NSError(
                    domain: "ArtistAlbumsViewModelTests",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "next page failed"]
                )
            )
        ]

        let sut = ArtistAlbumsViewModel(client: client, artistID: 77)

        await sut.fetchAlbums()
        await sut.loadNextPage()

        XCTAssertEqual(sut.albums.map(\.id), [1])
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.paginationErrorMessage, "Couldn't load more results. Please try again later.")
        XCTAssertFalse(sut.isLoadingMore)
    }

    @MainActor
    func test_fetchAlbums_failure_setsTopLevelErrorAndClearsPaginationError() async {
        let client = FakeHTTPClient()
        client.responses = [
            .failure(
                NSError(
                    domain: "ArtistAlbumsViewModelTests",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "first page failed"]
                )
            )
        ]

        let sut = ArtistAlbumsViewModel(client: client, artistID: 77)

        await sut.fetchAlbums()

        XCTAssertTrue(sut.albums.isEmpty)
        XCTAssertEqual(sut.errorMessage, "Failed to load albums. Please try again later.")
        XCTAssertNil(sut.paginationErrorMessage)
        XCTAssertFalse(sut.isFirstLoading)
        XCTAssertFalse(sut.isLoadingMore)
    }
}

private func makeAlbumsPayload(
    page: Int,
    pages: Int,
    releases: [(id: Int, title: String, year: Int?, format: String?, type: String?, label: String?)]
) -> Data {
    let releaseObjects: [[String: Any]] = releases.map { release in
        var object: [String: Any] = [
            "id": release.id,
            "title": release.title
        ]
        if let year = release.year {
            object["year"] = year
        }
        if let format = release.format {
            object["format"] = format
        }
        if let type = release.type {
            object["type"] = type
        }
        if let label = release.label {
            object["label"] = label
        }
        return object
    }

    let payload: [String: Any] = [
        "pagination": [
            "page": page,
            "pages": pages,
            "per_page": 30,
            "items": releases.count
        ],
        "releases": releaseObjects
    ]

    return try! JSONSerialization.data(withJSONObject: payload)
}
