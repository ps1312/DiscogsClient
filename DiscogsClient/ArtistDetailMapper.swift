import Foundation

class ArtistDetailMapper {
    static func map(_ data: Data, _ response: HTTPURLResponse, preserving item: Artist) throws -> Artist {
        let decoded = try JSONDecoder().decode(DiscogsArtist.self, from: data)
        
        return Artist(
            id: decoded.id,
            title: item.title,
            thumbUrl: item.thumbUrl,
            imageUrl: decoded.primaryImageURL,
            profile: decoded.profile
        )
    }
}
