import SwiftUI

struct ArtistSearchView: View {
    @ObservedObject private var viewModel: ArtistSearchViewModel
    @FocusState private var isSearchFieldFocused: Bool
    @State private var hasAppliedInitialSearchFocus = false
    private let makeArtistDetailView: (Artist) -> ArtistDetailView
    
    init(
        viewModel: ArtistSearchViewModel,
        makeArtistDetailView: @escaping (Artist) -> ArtistDetailView
    ) {
        self.viewModel = viewModel
        self.makeArtistDetailView = makeArtistDetailView
    }

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isFirstLoading, viewModel.paginated.items.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.paginated.items.isEmpty, !viewModel.isFirstLoading, viewModel.errorMessage == nil {
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
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            Text("Page \(viewModel.paginated.currentPage) / \(viewModel.paginated.totalPages)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }

                        List {
                            ForEach(viewModel.paginated.items) { artist in
                                NavigationLink {
                                    makeArtistDetailView(artist)
                                } label: {
                                    listItemRow(for: artist)
                                }
                                .onAppear {
                                    guard artist.id == viewModel.paginated.items.last?.id else { return }
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
            }
            .navigationTitle("Discogs")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $viewModel.searchText,
                prompt: "Search for artists...",
            )
            .searchFocused($isSearchFieldFocused)
            .onAppear {
                guard !hasAppliedInitialSearchFocus else { return }
                hasAppliedInitialSearchFocus = true
                isSearchFieldFocused = true
            }
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

            VStack(alignment: .leading, spacing: 4) {
                Text(artist.title)
                    .font(.headline)
                    .lineLimit(2)

                Text("ID: \(artist.id)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

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

