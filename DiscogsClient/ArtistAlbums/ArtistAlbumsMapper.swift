import Foundation

class ArtistAlbumsMapper {
    private struct Root: Decodable {
        let pagination: DiscogsPageMetadata
        let releases: [ArtistRelease]
    }

    struct PaginatedAlbums {
        let albums: [ArtistRelease]
        let page: Int
        let pages: Int
    }

    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> PaginatedAlbums {
        let decoded = try JSONDecoder().decode(Root.self, from: data)

        let albums = decoded.releases.filter {
            let formatText = $0.format?.lowercased() ?? ""
            let typeText = $0.type?.lowercased() ?? ""
            return formatText.contains("album") || typeText == "master"
        }

        return PaginatedAlbums(
            albums: albums,
            page: decoded.pagination.page,
            pages: decoded.pagination.pages
        )
    }
}
