import SwiftUI

struct ArtistSearchView: View {
    private let client: HTTPClient
    
    private let token = "gMBGYHrUBKsPAJRDmMTbGCLgHlJrdHbMxlCGOqSM"
    private let userAgent = "DiscogsClient/1.0"

    @State private var searchText = "Red hot"
    @State private var results: [Artist] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasSearched = false
    
    init(httpClient: HTTPClient) {
        self.client = httpClient
    }

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading, results.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if results.isEmpty, !isLoading, errorMessage == nil {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(.secondary)

                        Text(emptyStateTitle)
                            .font(.title3.weight(.semibold))

                        Text(emptyStateMessage)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    Spacer()
                } else {
                    List(results) { item in
                        NavigationLink {
                            ArtistDetailView(client: client, item: item)
                        } label: {
                            HStack(alignment: .center, spacing: 12) {
                                artwork(for: item.thumbUrl)
                                    .frame(width: 64, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                Text(item.title)
                                    .font(.headline)
                                    .lineLimit(2)

                                Spacer(minLength: 0)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Discogs")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                prompt: "Search for artists...",
            )
        }
        .task(id: searchText) {
            await debouncedSearch()
        }
    }

    @ViewBuilder
    private func artwork(for thumbUrl: URL?) -> some View {
        if let thumbUrl {
            AsyncImage(url: thumbUrl) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else if phase.error != nil {
                    fallbackArtworkIcon
                } else {
                    fallbackArtworkIcon
                }
            }
        } else {
            fallbackArtworkIcon
        }
    }

    private var fallbackArtworkIcon: some View {
        Image(systemName: "person.crop.circle.badge.exclamationmark")
            .font(.system(size: 28, weight: .light))
            .foregroundStyle(.secondary)
    }

    private func debouncedSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !query.isEmpty else {
            await MainActor.run {
                hasSearched = false
                results = []
                errorMessage = nil
                isLoading = false
            }
            return
        }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
            results = []
        }

        do {
            try await Task.sleep(nanoseconds: 500_000_000)
        } catch {
            return
        }

        await fetchDiscogsSearch(query: query)
    }

    private func fetchDiscogsSearch(query: String) async {
        await MainActor.run {
            hasSearched = true
            isLoading = true
            errorMessage = nil
        }

        do {
            let request = ApiRequestBuilder.search(query: query)
            let (data, response) = try await client.send(request)
            let artists = try ArtistSearchMapper.map(data, response)
            
            await MainActor.run {
                results = artists
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var emptyStateTitle: String {
        if !hasSearched {
            return "Start Searching"
        }

        if !trimmedSearchText.isEmpty {
            return "No Results"
        }

        return "No Recent Searches"
    }

    private var emptyStateMessage: String {
        if !hasSearched {
            return "Find artists on Discogs"
        }

        if !trimmedSearchText.isEmpty {
            return "No matches found for \"\(trimmedSearchText)\""
        }

        return "Your recent searches will appear here"
    }
}

#Preview {
    ArtistSearchView(httpClient: URLSession.shared)
}
