import Foundation

class ArtistDetailsRequest {
    static let token = "gMBGYHrUBKsPAJRDmMTbGCLgHlJrdHbMxlCGOqSM"
    static let userAgent = "DiscogsClient/1.0"

    static func create(artistId: Int) -> URLRequest {
        var request = URLRequest(url: URL(string: "https://api.discogs.com/artists/\(artistId)")!)
        request.httpMethod = "GET"
        request.setValue("Discogs token=\(Self.token)", forHTTPHeaderField: "Authorization")
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }
}
