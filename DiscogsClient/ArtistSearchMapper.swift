import Foundation

struct DiscogsArtistSearchResult: Decodable, Identifiable {
    let id: Int
    let title: String
    let type: String?
    let country: String?
    let year: Int?
    let thumb: String?

    var thumbnailURL: URL? {
        guard let thumb, !thumb.isEmpty else { return nil }
        return URL(string: thumb)
    }
}

class ArtistSearchMapper {
    struct PaginationResponse: Decodable {
        let page: Int
        let pages: Int
        let per_page: Int
        let items: Int
    }
    
    struct SearchResponse: Decodable {
        let pagination: PaginationResponse
        let results: [DiscogsArtistSearchResult]
    }
    
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [Artist] {
        let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
        return decoded.results.map {
            Artist(
                id: $0.id,
                title: $0.title,
                thumbUrl: $0.thumbnailURL
            )
        }
    }
}
