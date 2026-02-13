//
//  DiscogsArtistDetailView.swift
//  DiscogsClient
//
//  Created by Codex on 12/02/26.
//

import SwiftUI

struct ArtistDetailView: View {
    let item: DiscogsSearchResult
    let token: String
    let userAgent: String

    @State private var artist: DiscogsArtist?
    @State private var isLoadingArtist = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroSection

                VStack(alignment: .leading, spacing: 10) {
                    DetailRow(label: "Real Name", value: artist?.realname)
                    DetailRow(label: "Type", value: displayType)
                    DetailRow(label: "Country", value: item.country)
                    DetailRow(label: "Year", value: item.year.map(String.init))
                    DetailRow(label: "Discogs ID", value: String(item.id))
                }
                .padding(.horizontal, 20)

                if !bandMembers.isEmpty || !profileText.isEmpty {
                    Divider()
                        .padding(.horizontal, 20)
                }

                if !bandMembers.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Members")
                            .font(.headline)

                        ForEach(Array(bandMembers.enumerated()), id: \.element.id) { index, member in
                            HStack(spacing: 10) {
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(member.name)
                                    .font(.body)
                                if index == bandMembers.count - 1 {
                                    Text("Past")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(.secondary.opacity(0.15), in: Capsule())
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal, 20)

                    if !profileText.isEmpty {
                        Divider()
                            .padding(.horizontal, 20)
                    }
                }

                if !profileText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profile")
                            .font(.headline)

                        Text(profileText)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 20)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.black)
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.large)
        .task(id: item.id) {
            await fetchArtistDetails()
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            artwork
                .background(Color.gray.opacity(0.15))
                .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            heroOverlayContent
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 8)
    }

    private var heroOverlayContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !profilePreview.isEmpty {
                Text(profilePreview)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)
            }

            Text(displayType)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.78))

            HStack(spacing: 10) {
                NavigationLink {
                    ArtistAlbumsView(
                        artistID: item.id,
                        token: token,
                        userAgent: userAgent
                    )
                    .navigationTitle("Albums")
                    .navigationBarTitleDisplayMode(.inline)
                } label: {
                    Label("Albums", systemImage: "opticaldisc")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.16), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 16)
    }

    @ViewBuilder
    private var artwork: some View {
        if let artworkURL = artist?.primaryImageURL ?? item.thumbnailURL {
            AsyncImage(url: artworkURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else if phase.error != nil {
                    fallbackArtwork
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.gray.opacity(0.15))
                        ProgressView()
                    }
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
                .frame(height: 256)
        }
    }

    private var displayName: String {
        artist?.name ?? item.title
    }

    private var profileText: String {
        guard let profile = artist?.profile else { return "" }
        return cleanProfile(profile)
    }

    private var profilePreview: String {
        guard !profileText.isEmpty else { return "" }
        let maxLength = 140
        if profileText.count <= maxLength {
            return profileText
        }

        let end = profileText.index(profileText.startIndex, offsetBy: maxLength)
        return String(profileText[..<end]).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }

    private var displayType: String {
        bandMembers.isEmpty ? (item.type?.capitalized ?? "Artist") : "Band"
    }

    private var bandMembers: [DiscogsArtistMember] {
        guard let members = artist?.members else { return [] }
        return members.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
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
    let members: [DiscogsArtistMember]?

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

struct DiscogsArtistMember: Decodable, Identifiable {
    let id: Int
    let name: String
    let active: Bool?
}
