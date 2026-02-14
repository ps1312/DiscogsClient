import SwiftUI

struct ArtistSearchView: View {
    private let client: HTTPClient

    @ObservedObject private var viewModel: ArtistSearchViewModel
    
    init(httpClient: HTTPClient, viewModel: ArtistSearchViewModel) {
        self.client = httpClient
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isFirstLoading, viewModel.results.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.results.isEmpty, !viewModel.isFirstLoading, viewModel.errorMessage == nil {
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
                    List {
                        ForEach(viewModel.results) { artist in
                            NavigationLink {
                                ArtistDetailView(client: client, item: artist)
                            } label: {
                                listItemRow(for: artist)
                            }
                            .onAppear {
                                guard artist.id == viewModel.results.last?.id else { return }
                                Task { await viewModel.loadNextPage() }
                            }
                        }

                        if viewModel.isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Discogs")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $viewModel.searchText,
                prompt: "Search for artists...",
            )
        }
        .task(id: viewModel.searchText) {
            await viewModel.searchDebounced(query: viewModel.searchText)
        }
    }
   
    private func listItemRow(for artist: Artist) -> some View {
        HStack(alignment: .center, spacing: 12) {
            AsyncImageWithFallback(url: artist.thumbUrl)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(artist.title)
                .font(.headline)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
    }

    private var trimmedSearchText: String {
        viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var emptyStateTitle: String {
        if !viewModel.hasSearched {
            return "Start Searching"
        }

        if !trimmedSearchText.isEmpty {
            return "No Results"
        }

        return "No Recent Searches"
    }

    private var emptyStateMessage: String {
        if !viewModel.hasSearched {
            return "Find artists on Discogs"
        }

        if !trimmedSearchText.isEmpty {
            return "No matches found for \"\(trimmedSearchText)\""
        }

        return "Your recent searches will appear here"
    }
}

#Preview {
    ArtistSearchView(
        httpClient: URLSession.shared,
        viewModel: ArtistSearchViewModel(client: URLSession.shared)
    )
}
