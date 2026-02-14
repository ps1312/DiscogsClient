import SwiftUI

struct ArtistAlbumsView: View {
    @StateObject private var viewModel: ArtistAlbumsViewModel

    @State private var selectedYear: Int?
    @State private var selectedLabel: String?

    init(viewModel: ArtistAlbumsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var albums: [ArtistRelease] {
        viewModel.paginated.items
    }

    private var filteredAlbums: [ArtistRelease] {
        albums.filter { release in
            let matchesYear = selectedYear == nil || release.year == selectedYear
            let matchesLabel = selectedLabel == nil || release.label == selectedLabel
            return matchesYear && matchesLabel
        }
    }

    var body: some View {
        Group {
            if viewModel.isFirstLoading && albums.isEmpty {
                ProgressView()
            } else if albums.isEmpty, let errorMessage = viewModel.errorMessage {
                ContentUnavailableView {
                    Label {
                        Text("Albums Failed")
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(.red)
                    }
                } description: {
                    Text(errorMessage)
                }
            } else if albums.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "opticaldisc")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(.secondary)
                    Text("No albums found")
                        .font(.headline)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ArtistAlbumsFilterView(
                        viewModel: viewModel,
                        selectedYear: $selectedYear,
                        selectedLabel: $selectedLabel
                    )

                    if filteredAlbums.isEmpty {
                        ContentUnavailableView(
                            "No results",
                            systemImage: "line.3.horizontal.decrease.circle",
                            description: Text("Try clearing one or more filters.")
                        )
                    }

                    List {
                        ForEach(filteredAlbums) { release in
                            HStack(spacing: 12) {
                                AsyncImageWithFallback(url: release.thumbnailURL)
                                    .frame(width: 54, height: 54)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(release.title)
                                        .font(.headline)
                                        .lineLimit(2)
                                    Text(metadataText(for: release))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                            .onAppear {
                                guard release.id == filteredAlbums.last?.id else { return }
                                Task { await viewModel.loadNextPage() }
                            }
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
                    .listRowSeparator(.hidden)

                    if viewModel.isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .task(id: viewModel.artistID) {
            await viewModel.fetchAlbums()
            selectedYear = nil
            selectedLabel = nil
        }
    }

    private func metadataText(for release: ArtistRelease) -> String {
        var parts: [String] = [release.year.map(String.init) ?? "Unknown year"]
        if let label = release.label {
            parts.append(label)
        }
        parts.append("ID: \(release.id)")
        return parts.joined(separator: " • ")
    }
}
