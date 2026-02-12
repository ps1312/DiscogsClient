//
//  DiscogsArtistDetailView.swift
//  DiscogsClient
//
//  Created by Codex on 12/02/26.
//

import SwiftUI

struct DiscogsArtistDetailView: View {
    let item: DiscogsSearchResult
    let token: String
    let userAgent: String

    @State private var artist: DiscogsArtist?
    @State private var isLoadingArtist = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                artwork
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "Real Name", value: artist?.realname)
                    DetailRow(label: "Type", value: item.type?.capitalized)
                    DetailRow(label: "Country", value: item.country)
                    DetailRow(label: "Year", value: item.year.map(String.init))
                    DetailRow(label: "Discogs ID", value: String(item.id))
                    
                    NavigationLink {
                        DiscogsArtistAlbumsView(
                            artistID: item.id,
                            artistName: artist?.name ?? item.title,
                            token: token,
                            userAgent: userAgent
                        )
                    } label: {
                        Label("See Albums", systemImage: "opticaldisc")
                            .font(.headline)
                    }
                    .padding(.top, 8)

                    if let profile = artist?.profile, !profile.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Profile")
                            .font(.headline)
                            .padding(.top, 8)

                        Text(cleanProfile(profile))
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                if isLoadingArtist {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Loading artist details...")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
        .navigationTitle(artist?.name ?? item.title)
        .navigationBarTitleDisplayMode(.large)
        .task(id: item.id) {
            await fetchArtistDetails()
        }
    }

    @ViewBuilder
    private var artwork: some View {
        if let artworkURL = artist?.primaryImageURL ?? item.thumbnailURL {
            AsyncImage(url: artworkURL) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.gray.opacity(0.15))
                        ProgressView()
                    }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    fallbackArtwork
                @unknown default:
                    fallbackArtwork
                }
            }
        } else {
            fallbackArtwork
        }
    }

    private var fallbackArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.gray.opacity(0.15))
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 58, weight: .light))
                .foregroundStyle(.secondary)
        }
    }

    private func fetchArtistDetails() async {
        await MainActor.run {
            isLoadingArtist = true
            errorMessage = nil
        }

        var request = URLRequest(url: URL(string: "https://api.discogs.com/artists/\(item.id)")!)
        request.httpMethod = "GET"
        request.setValue("Discogs token=\(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, !(200 ... 299).contains(httpResponse.statusCode) {
                await MainActor.run {
                    isLoadingArtist = false
                    errorMessage = "Failed to load artist details (HTTP \(httpResponse.statusCode))."
                }
                return
            }

            let decoded = try JSONDecoder().decode(DiscogsArtist.self, from: data)
            await MainActor.run {
                artist = decoded
                isLoadingArtist = false
            }
        } catch {
            await MainActor.run {
                isLoadingArtist = false
                errorMessage = "Failed to load artist details: \(error.localizedDescription)"
            }
        }
    }

    private func cleanProfile(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\[(a|r|m|l)=\\d+\\]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\n\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct DetailRow: View {
    let label: String
    let value: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label + ":")
                .font(.subheadline.weight(.semibold))
            Text(value ?? "N/A")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

struct DiscogsArtist: Decodable {
    let id: Int
    let name: String
    let realname: String?
    let profile: String?
    let images: [DiscogsArtistImage]?

    var primaryImageURL: URL? {
        guard let images else { return nil }
        
        let preferred = images.first(where: { $0.type == "primary" }) ?? images.first
        
        if let uri = preferred?.uri, !uri.isEmpty {
            return URL(string: uri)
        }
        
        return nil
    }
}

struct DiscogsArtistImage: Decodable {
    let type: String?
    let uri: String?
}
