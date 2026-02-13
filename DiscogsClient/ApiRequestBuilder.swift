import Foundation

class ApiRequestBuilder {
    private static let token = "gMBGYHrUBKsPAJRDmMTbGCLgHlJrdHbMxlCGOqSM"
    private static let userAgent = "DiscogsClient/1.0"
    
    static func search(query: String) -> URLRequest {
        var components = URLComponents(string: "https://api.discogs.com/database/search")!
        
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "artist"),
            URLQueryItem(name: "per_page", value: "30")
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        
        return addAuthHeaders(to: request)
    }
    
    static func details(for artistId: Int) -> URLRequest {
        var request = URLRequest(url: URL(string: "https://api.discogs.com/artists/\(artistId)")!)
        request.httpMethod = "GET"
        
        return addAuthHeaders(to: request)
    }
    
    private static func addAuthHeaders(to request: URLRequest) -> URLRequest {
        var request = request
        request.setValue("Discogs token=\(Self.token)", forHTTPHeaderField: "Authorization")
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        
        return request
    }
}
