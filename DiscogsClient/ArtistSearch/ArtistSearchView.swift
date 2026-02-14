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
                } else if viewModel.paginated.items.isEmpty, let errorMessage = viewModel.errorMessage {
                    ContentUnavailableView {
                        Label {
                            Text("Search Failed")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle")
                                .symbolRenderingMode(.monochrome)
                                .foregroundStyle(.red)
                        }
                    } description: {
                        Text(errorMessage)
                    }
                } else if viewModel.paginated.items.isEmpty, !viewModel.isFirstLoading, viewModel.errorMessage == nil {
                    if viewModel.hasSearched, !viewModel.trimmedSearchText.isEmpty {
                        NoResultsEmptyView(query: viewModel.trimmedSearchText)
                    } else {
                        InitialSearchEmptyView()
                    }
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

                            if let paginationErrorMessage = viewModel.paginationErrorMessage {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text(paginationErrorMessage)
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowSeparator(.hidden)
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

}

private struct InitialSearchEmptyView: View {
    var body: some View {
        ContentUnavailableView(
            "Start Searching",
            systemImage: "magnifyingglass",
            description: Text("Find artists on Discogs")
        )
    }
}

private struct NoResultsEmptyView: View {
    let query: String

    var body: some View {
        ContentUnavailableView(
            "No Results",
            systemImage: "magnifyingglass",
            description: Text("No matches found for \"\(query)\"")
        )
    }
}
