import Foundation

class ArtistSearchRequest {
    static let token = "gMBGYHrUBKsPAJRDmMTbGCLgHlJrdHbMxlCGOqSM"
    static let userAgent = "DiscogsClient/1.0"
    
    static func create(url: String, query: String) -> URLRequest {
        var components = URLComponents(string: url)!
        
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "artist"),
            URLQueryItem(name: "per_page", value: "30")
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Discogs token=\(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        return request
    }
}
