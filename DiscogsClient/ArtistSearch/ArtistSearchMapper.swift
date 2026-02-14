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
    
    private struct PageMetadata: Decodable {
        let page: Int
        let pages: Int
        let per_page: Int
        let items: Int
    }
    
    private struct Root: Decodable {
        let pagination: PageMetadata
        let results: [DiscogsArtistSearchResult]
    }

    struct PaginatedArtists {
        let artists: [Artist]
        let page: Int
        let pages: Int
    }

    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> PaginatedArtists {
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
        return PaginatedArtists(
            artists: models,
            page: decoded.pagination.page,
            pages: decoded.pagination.pages
        )
    }
}
