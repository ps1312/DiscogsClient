//
//  DiscogsArtistAlbumsView.swift
//  DiscogsClient
//
//  Created by Codex on 12/02/26.
//

import SwiftUI

struct DiscogsArtistAlbumsView: View {
    let artistID: Int
    let token: String
    let userAgent: String

    @State private var albums: [DiscogsArtistRelease] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

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
                    List(albums) { release in
                        HStack(spacing: 12) {
                            albumArtwork(for: release)
                                .frame(width: 54, height: 54)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(release.title)
                                    .font(.headline)
                                    .lineLimit(2)
                                Text(release.year.map(String.init) ?? "Unknown year")
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

        var components = URLComponents(string: "https://api.discogs.com/artists/\(artistID)/releases")!
        components.queryItems = [
            URLQueryItem(name: "per_page", value: "100"),
            URLQueryItem(name: "sort", value: "year"),
            URLQueryItem(name: "sort_order", value: "desc")
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Discogs token=\(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, !(200 ... 299).contains(httpResponse.statusCode) {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to load albums (HTTP \(httpResponse.statusCode))."
                }
                return
            }

            let decoded = try JSONDecoder().decode(DiscogsArtistReleasesResponse.self, from: data)
            let filteredAlbums = decoded.releases.filter(\.isAlbum)

            await MainActor.run {
                albums = filteredAlbums
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
