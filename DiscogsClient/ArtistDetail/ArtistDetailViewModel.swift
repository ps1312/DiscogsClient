import Foundation
import Combine

@MainActor
final class ArtistDetailViewModel: ObservableObject {
    @Published private(set) var artist: Artist
    @Published private(set) var isLoadingArtist = false
    @Published private(set) var errorMessage: String?

    private let client: HTTPClient

    init(client: HTTPClient, existing: Artist) {
        self.client = client
        self.artist = existing
    }

    func fetchArtistDetails() async {
        isLoadingArtist = true
        errorMessage = nil

        do {
            let request = ApiRequestBuilder.details(for: artist.id)
            let (data, response) = try await client.send(request)
            artist = try ArtistDetailMapper.map(data, response, preserving: artist)
            isLoadingArtist = false
        } catch {
            isLoadingArtist = false
            errorMessage = "Failed to load artist details: \(error.localizedDescription)"
        }
    }
}
