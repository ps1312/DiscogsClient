import Foundation
import Combine

@MainActor
final class ArtistDetailViewModel: ObservableObject {
    @Published private(set) var artist: Artist
    @Published private(set) var isLoadingArtist = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var hasFetchedDetails = false

    private let client: HTTPClient

    init(client: HTTPClient, existing: Artist) {
        self.client = client
        self.artist = existing
    }

    func fetchArtistDetailsIfNeeded() async {
        guard !hasFetchedDetails, !isLoadingArtist else { return }
        await fetchArtistDetails()
    }

    func fetchArtistDetails() async {
        isLoadingArtist = true
        errorMessage = nil

        do {
            let request = ApiRequestBuilder.details(for: artist.id)
            let (data, response) = try await client.send(request)
            artist = try ArtistDetailMapper.map(data, response, preserving: artist)
            hasFetchedDetails = true
            isLoadingArtist = false
        } catch {
            isLoadingArtist = false
            errorMessage = "Failed to load artist details: \(error.localizedDescription)"
        }
    }
}
