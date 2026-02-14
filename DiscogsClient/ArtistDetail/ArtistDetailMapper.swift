import Foundation

class ArtistDetailMapper {
    struct DiscogsArtistImage: Decodable {
        let type: String
        let uri: String
    }

    struct DiscogsArtistDetailResult: Decodable {
        let id: Int
        let name: String
        let profile: String?
        let images: [DiscogsArtistImage]?
        let members: [BandMember]?
    }

    static func map(_ data: Data, _ response: HTTPURLResponse, preserving existing: Artist) throws -> Artist {
        let artist = try JSONDecoder().decode(DiscogsArtistDetailResult.self, from: data)

        return Artist(
            id: artist.id,
            title: existing.title,
            thumbUrl: existing.thumbUrl,
            imageUrl: findPrimaryImageUrl(artist.images),
            profile: artist.profile,
            bandMembers: artist.members
        )
    }

    private static func findPrimaryImageUrl(_ images: [DiscogsArtistImage]?) -> URL? {
        var imageUrl: URL?

        if let primaryImage = images?.first(where: { $0.type == "primary" }) {
            imageUrl = URL(string: primaryImage.uri)
        }

        return imageUrl
    }
}
