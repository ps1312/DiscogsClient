import XCTest
@testable import DiscogsClient

final class ArtistAlbumsMapperTests: XCTestCase {
    func test_map_filtersReleasesBySelectedArtist() throws {
        let payload = makeMapperAlbumsPayload(
            page: 1,
            pages: 1,
            releases: [
                (id: 1, title: "Correct Artist Album", format: "Album", type: "release", artist: "Daft Punk"),
                (id: 2, title: "Other Artist Album", format: "Album", type: "release", artist: "Justice")
            ]
        )
        let response = HTTPURLResponse(
            url: URL(string: "https://api.discogs.com/artists/77/releases")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let result = try ArtistAlbumsMapper.map(
            payload,
            response,
            selectedArtistName: "Daft Punk"
        )

        XCTAssertEqual(result.items.map(\.id), [1])
    }
}

private func makeMapperAlbumsPayload(
    page: Int,
    pages: Int,
    releases: [(id: Int, title: String, format: String?, type: String?, artist: String?)]
) -> Data {
    let releaseObjects: [[String: Any]] = releases.map { release in
        var object: [String: Any] = [
            "id": release.id,
            "title": release.title
        ]
        if let format = release.format {
            object["format"] = format
        }
        if let type = release.type {
            object["type"] = type
        }
        if let artist = release.artist {
            object["artist"] = artist
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
