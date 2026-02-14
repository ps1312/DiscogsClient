import Foundation
@testable import DiscogsClient

final class FakeHTTPClient: HTTPClient {
    enum Response {
        case success(data: Data, statusCode: Int)
        case failure(Error)
    }

    var responses: [Response] = []
    private(set) var requests: [URLRequest] = []

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)

        guard !responses.isEmpty else {
            throw NSError(
                domain: "FakeHTTPClient",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No stubbed response available"]
            )
        }

        let response = responses.removeFirst()
        switch response {
        case let .success(data, statusCode):
            let url = request.url ?? URL(string: "https://api.discogs.com")!
            let httpResponse = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (data, httpResponse)
        case let .failure(error):
            throw error
        }
    }
}
