import XCTest
@testable import DiscogsClient

final class ArtistDetailViewModelTests: XCTestCase {
    @MainActor
    func test_fetchArtistDetails_success_updatesArtistFromResponse() async throws {
        let existingArtist = Artist(
            id: 42,
            title: "Initial Name",
            thumbUrl: URL(string: "https://img.example/thumb.jpg"),
            imageUrl: nil,
            profile: nil,
            bandMembers: nil
        )

        let client = FakeHTTPClient()
        client.responses = [
            .success(
                data: makeArtistDetailPayload(
                    id: existingArtist.id,
                    name: "Returned Name",
                    profile: "Legendary artist profile",
                    primaryImageURL: "https://img.example/primary.jpg",
                    members: [
                        (id: 1, name: "Member One", active: true),
                        (id: 2, name: "Member Two", active: false)
                    ]
                ),
                statusCode: 200
            )
        ]

        let sut = ArtistDetailViewModel(client: client, existing: existingArtist)

        await sut.fetchArtistDetails()

        XCTAssertFalse(sut.isLoadingArtist)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.artist.id, existingArtist.id)
        XCTAssertEqual(sut.artist.title, "Initial Name")
        XCTAssertEqual(sut.artist.thumbUrl?.absoluteString, "https://img.example/thumb.jpg")
        XCTAssertEqual(sut.artist.imageUrl?.absoluteString, "https://img.example/primary.jpg")
        XCTAssertEqual(sut.artist.profile, "Legendary artist profile")
        XCTAssertEqual(sut.artist.bandMembers?.map(\.name), ["Member One", "Member Two"])
        XCTAssertEqual(sut.artist.bandMembers?.map(\.id), [1, 2])

        XCTAssertEqual(client.requests.count, 1)
        let request = try XCTUnwrap(client.requests.first)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.absoluteString, "https://api.discogs.com/artists/42")
    }

    @MainActor
    func test_fetchArtistDetails_failure_keepsExistingArtistAndSetsError() async {
        let existingArtist = Artist(
            id: 77,
            title: "Existing Artist",
            thumbUrl: URL(string: "https://img.example/existing-thumb.jpg"),
            imageUrl: URL(string: "https://img.example/existing-image.jpg"),
            profile: "Existing profile",
            bandMembers: [BandMember(id: 10, name: "Existing Member", active: true)]
        )

        let client = FakeHTTPClient()
        client.responses = [
            .failure(
                NSError(
                    domain: "ArtistDetailViewModelTests",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "request failed"]
                )
            )
        ]

        let sut = ArtistDetailViewModel(client: client, existing: existingArtist)

        await sut.fetchArtistDetails()

        XCTAssertFalse(sut.isLoadingArtist)
        XCTAssertEqual(
            sut.errorMessage,
            "Failed to load artist details: request failed"
        )
        XCTAssertEqual(sut.artist.id, 77)
        XCTAssertEqual(sut.artist.title, "Existing Artist")
        XCTAssertEqual(sut.artist.profile, "Existing profile")
        XCTAssertEqual(sut.artist.bandMembers?.map(\.name), ["Existing Member"])
    }
}

private func makeArtistDetailPayload(
    id: Int,
    name: String,
    profile: String?,
    primaryImageURL: String?,
    members: [(id: Int, name: String, active: Bool)]
) -> Data {
    let memberPayloads: [[String: Any]] = members.map { member in
        [
            "id": member.id,
            "name": member.name,
            "active": member.active
        ]
    }

    var payload: [String: Any] = [
        "id": id,
        "name": name,
        "members": memberPayloads
    ]

    if let profile {
        payload["profile"] = profile
    }

    if let primaryImageURL {
        payload["images"] = [
            [
                "type": "primary",
                "uri": primaryImageURL
            ]
        ]
    }

    return try! JSONSerialization.data(withJSONObject: payload)
}
