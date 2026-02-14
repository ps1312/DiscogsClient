import Foundation
import Combine

@MainActor
final class ArtistAlbumsViewModel: ObservableObject {
    @Published private(set) var albums: [ArtistRelease] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    let artistID: Int

    private let client: HTTPClient
    private var isFetching = false

    init(client: HTTPClient, artistID: Int) {
        self.client = client
        self.artistID = artistID
    }

    func fetchAlbums() async {
        guard !isFetching else { return }

        isFetching = true
        isLoading = true
        errorMessage = nil
        albums = []
        defer {
            isFetching = false
            isLoading = false
        }

        do {
            let request = ApiRequestBuilder.artistReleases(for: artistID)
            let (data, response) = try await client.send(request)
            albums = try ArtistAlbumsMapper.map(data, response)
        } catch {
            errorMessage = "Failed to load albums: \(error.localizedDescription)"
        }
    }
}
