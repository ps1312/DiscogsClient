import Foundation

class ArtistSearchMapper {
    private struct DiscogsArtistSearchResult: Decodable, Identifiable {
        let id: Int
        let title: String
        let type: String
        let thumb: String?

        var thumbnailURL: URL? {
            guard let thumb, !thumb.isEmpty else { return nil }
            return URL(string: thumb)
        }
    }
    
    private struct Root: Decodable {
        let pagination: DiscogsPageMetadata
        let results: [DiscogsArtistSearchResult]
    }

    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> Paginated<Artist> {
        let decoded = try JSONDecoder().decode(Root.self, from: data)
        let models = decoded.results.map {
            Artist(
                id: $0.id,
                title: $0.title,
                thumbUrl: $0.thumbnailURL,
                imageUrl: nil,
                profile: nil,
                bandMembers: nil
            )
        }
        return Paginated(
            items: models,
            currentPage: decoded.pagination.page,
            totalPages: decoded.pagination.pages
        )
    }
}
