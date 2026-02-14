import XCTest
@testable import DiscogsClient

final class ArtistDetailViewModelTests: XCTestCase {
    @MainActor
    func test_fetchArtistDetailsIfNeeded_firstCall_fetchesDetails() async {
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
                    members: [(id: 1, name: "Member One", active: true)]
                ),
                statusCode: 200
            )
        ]

        let sut = ArtistDetailViewModel(client: client, existing: existingArtist)

        await sut.fetchArtistDetailsIfNeeded()

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertTrue(sut.hasFetchedDetails)
        XCTAssertNil(sut.errorMessage)
    }

    @MainActor
    func test_fetchArtistDetailsIfNeeded_afterSuccess_doesNotFetchAgain() async {
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
                    members: [(id: 1, name: "Member One", active: true)]
                ),
                statusCode: 200
            ),
            .failure(
                NSError(
                    domain: "ArtistDetailViewModelTests",
                    code: 99,
                    userInfo: [NSLocalizedDescriptionKey: "should not be called"]
                )
            )
        ]

        let sut = ArtistDetailViewModel(client: client, existing: existingArtist)

        await sut.fetchArtistDetailsIfNeeded()
        await sut.fetchArtistDetailsIfNeeded()

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertTrue(sut.hasFetchedDetails)
        XCTAssertNil(sut.errorMessage)
    }

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
            "Failed to load artist details. Please try again later."
        )
        XCTAssertEqual(sut.artist.id, 77)
        XCTAssertEqual(sut.artist.title, "Existing Artist")
        XCTAssertEqual(sut.artist.profile, "Existing profile")
        XCTAssertEqual(sut.artist.bandMembers?.map(\.name), ["Existing Member"])
    }

    @MainActor
    func test_fetchArtistDetails_whenResponseHasNoBandMembers_setsBandMembersToNil() async {
        let existingArtist = Artist(
            id: 88,
            title: "No Members Artist",
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
                    name: "No Members Artist",
                    profile: "Profile without members",
                    primaryImageURL: "https://img.example/primary.jpg",
                    members: nil
                ),
                statusCode: 200
            )
        ]

        let sut = ArtistDetailViewModel(client: client, existing: existingArtist)

        await sut.fetchArtistDetails()

        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.artist.id, 88)
        XCTAssertEqual(sut.artist.profile, "Profile without members")
        XCTAssertNil(sut.artist.bandMembers)
    }
    
    @MainActor
    func test_orderedBandMembers_activeMembersComeFirst() async {
        let existingArtist = Artist(
            id: 42,
            title: "Band",
            thumbUrl: nil,
            imageUrl: nil,
            profile: nil,
            bandMembers: [
                BandMember(id: 1, name: "Inactive One", active: false),
                BandMember(id: 2, name: "Active One", active: true),
                BandMember(id: 3, name: "Inactive Two", active: false),
                BandMember(id: 4, name: "Active Two", active: true)
            ]
        )
        let sut = ArtistDetailViewModel(client: FakeHTTPClient(), existing: existingArtist)
        
        await sut.fetchArtistDetails()

        XCTAssertEqual(
            sut.orderedBandMembers?.map(\.name),
            ["Active One", "Active Two", "Inactive One", "Inactive Two"]
        )
        XCTAssertEqual(sut.orderedBandMembers?.map(\.id), [2, 4, 1, 3])
    }
}

private func makeArtistDetailPayload(
    id: Int,
    name: String,
    profile: String?,
    primaryImageURL: String?,
    members: [(id: Int, name: String, active: Bool)]?
) -> Data {
    var payload: [String: Any] = [
        "id": id,
        "name": name
    ]

    if let members {
        payload["members"] = members.map { member in
            [
                "id": member.id,
                "name": member.name,
                "active": member.active
            ]
        }
    }

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
