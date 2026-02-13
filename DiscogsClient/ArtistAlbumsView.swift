import SwiftUI

struct ArtistAlbumsView: View {
    let client: HTTPClient
    let artistID: Int

    @State private var albums: [DiscogsArtistRelease] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedYear: Int?
    @State private var selectedGenre: String?
    @State private var selectedLabel: String?

    private var availableYears: [Int] {
        Array(Set(albums.compactMap(\.year))).sorted(by: >)
    }

    private var availableGenres: [String] {
        Array(Set(albums.flatMap(\.genreNames))).sorted()
    }

    private var availableLabels: [String] {
        Array(Set(albums.compactMap(\.labelName))).sorted()
    }

    private var filteredAlbums: [DiscogsArtistRelease] {
        albums.filter { release in
            let matchesYear = selectedYear == nil || release.year == selectedYear
            let matchesGenre = selectedGenre.map(release.genreNames.contains) ?? true
            let matchesLabel = selectedLabel == nil || release.labelName == selectedLabel
            return matchesYear && matchesGenre && matchesLabel
        }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
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
                            albumArtwork(for: release)
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
        .task(id: artistID) {
            await fetchAlbums()
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
                Button("All Genres") { selectedGenre = nil }
                ForEach(availableGenres, id: \.self) { genre in
                    Button(genre) { selectedGenre = genre }
                }
            } label: {
                filterChip(title: selectedGenre ?? "Genre")
            }
            .frame(width: 124)

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

    private func metadataText(for release: DiscogsArtistRelease) -> String {
        var parts: [String] = [release.year.map(String.init) ?? "Unknown year"]
        if let genre = release.genreNames.first {
            parts.append(genre)
        }
        if let label = release.labelName {
            parts.append(label)
        }
        return parts.joined(separator: " • ")
    }

    @ViewBuilder
    private func albumArtwork(for release: DiscogsArtistRelease) -> some View {
        AsyncImage(url: release.thumbnailURL) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                Image(systemName: "opticaldisc")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func fetchAlbums() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            albums = []
        }
        
        do {
            let request = ApiRequestBuilder.artistReleases(for: artistID)
            let (data, _) = try await client.send(request)

            let decoded = try JSONDecoder().decode(DiscogsArtistReleasesResponse.self, from: data)
            let filteredAlbums = decoded.releases.filter(\.isAlbum)

            await MainActor.run {
                albums = filteredAlbums
                selectedYear = nil
                selectedGenre = nil
                selectedLabel = nil
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to load albums: \(error.localizedDescription)"
            }
        }
    }
}

private struct DiscogsArtistReleasesResponse: Decodable {
    let releases: [DiscogsArtistRelease]
}

struct DiscogsArtistRelease: Decodable, Identifiable {
    let id: Int
    let title: String
    let year: Int?
    let thumb: String?
    let format: String?
    let type: String?
    let genreNames: [String]
    let labelName: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case year
        case thumb
        case format
        case type
        case genre
        case genres
        case label
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        year = try container.decodeIfPresent(Int.self, forKey: .year)
        thumb = try container.decodeIfPresent(String.self, forKey: .thumb)
        format = try container.decodeIfPresent(String.self, forKey: .format)
        type = try container.decodeIfPresent(String.self, forKey: .type)

        let singleGenre = try container.decodeIfPresent(String.self, forKey: .genre).map { [$0] } ?? []
        let multipleGenres = try container.decodeIfPresent([String].self, forKey: .genres) ?? []
        genreNames = Array(Set(singleGenre + multipleGenres)).sorted()

        labelName = try container.decodeIfPresent(String.self, forKey: .label)
    }

    var thumbnailURL: URL? {
        guard let thumb, !thumb.isEmpty else { return nil }
        return URL(string: thumb)
    }

    var isAlbum: Bool {
        let formatText = format?.lowercased() ?? ""
        let typeText = type?.lowercased() ?? ""
        return formatText.contains("album") || typeText == "master"
    }
}
