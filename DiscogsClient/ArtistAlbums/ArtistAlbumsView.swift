import SwiftUI

struct ArtistAlbumsView: View {
    @StateObject private var viewModel: ArtistAlbumsViewModel

    @State private var selectedYear: Int?
    @State private var selectedGenre: String?
    @State private var selectedLabel: String?

    init(viewModel: ArtistAlbumsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var availableYears: [Int] {
        Array(Set(viewModel.albums.compactMap(\.year))).sorted(by: >)
    }

    private var availableLabels: [String] {
        Array(Set(viewModel.albums.compactMap(\.label))).sorted()
    }

    private var filteredAlbums: [ArtistRelease] {
        viewModel.albums.filter { release in
            let matchesYear = selectedYear == nil || release.year == selectedYear
            let matchesLabel = selectedLabel == nil || release.label == selectedLabel
            return matchesYear && matchesLabel
        }
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
            } else if viewModel.albums.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "opticaldisc")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(.secondary)
                    Text("No albums found")
                        .font(.headline)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    filterControls

                    if filteredAlbums.isEmpty {
                        ContentUnavailableView(
                            "No results",
                            systemImage: "line.3.horizontal.decrease.circle",
                            description: Text("Try clearing one or more filters.")
                        )
                    }

                    List(filteredAlbums) { release in
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
                    }
                    .listRowSeparator(.hidden)
                }
            }
        }
        .task(id: viewModel.artistID) {
            await viewModel.fetchAlbums()
            selectedYear = nil
            selectedGenre = nil
            selectedLabel = nil
        }
    }

    private var filterControls: some View {
        HStack(spacing: 8) {
            Menu {
                Button("All Years") { selectedYear = nil }
                ForEach(availableYears, id: \.self) { year in
                    Button(String(year)) { selectedYear = year }
                }
            } label: {
                filterChip(title: selectedYear.map(String.init) ?? "Year")
            }
            .frame(width: 108)

            Menu {
                Button("All Labels") { selectedLabel = nil }
                ForEach(availableLabels, id: \.self) { label in
                    Button(label) { selectedLabel = label }
                }
            } label: {
                filterChip(title: selectedLabel ?? "Label")
            }
            .frame(width: 124)
        }
        .padding(.horizontal)
        .animation(.none, value: selectedYear)
        .animation(.none, value: selectedGenre)
        .animation(.none, value: selectedLabel)
    }

    private func filterChip(title: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.down")
                .font(.caption2)
        }
        .font(.subheadline)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(uiColor: .secondarySystemFill), in: Capsule())
    }

    private func metadataText(for release: ArtistRelease) -> String {
        var parts: [String] = [release.year.map(String.init) ?? "Unknown year"]
        if let label = release.label {
            parts.append(label)
        }
        return parts.joined(separator: " • ")
    }
}
