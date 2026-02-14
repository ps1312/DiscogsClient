import Foundation

class ArtistAlbumsMapper {
    private struct Root: Decodable {
        let pagination: DiscogsPageMetadata
        let releases: [ArtistRelease]
    }

    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [ArtistRelease] {
        let decoded = try JSONDecoder().decode(Root.self, from: data)
        
        return decoded.releases.filter {
            let formatText = $0.format?.lowercased() ?? ""
            let typeText = $0.type?.lowercased() ?? ""
            return formatText.contains("album") || typeText == "master"
        }
    }
}
