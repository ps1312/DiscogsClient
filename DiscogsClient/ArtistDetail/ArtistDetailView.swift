import SwiftUI

struct ArtistDetailView: View {
    let client: HTTPClient

    @State private var item: Artist
    @State private var artist: DiscogsArtist?
    @State private var isLoadingArtist = false
    @State private var errorMessage: String?
    
    init(client: HTTPClient,item: Artist) {
        self.client = client
        _item = State(initialValue: item)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                artwork
                    .clipped()

                VStack(alignment: .leading, spacing: 10) {
                    DetailRow(label: "Discogs ID", value: String(item.id))
                    DetailRow(label: "Type", value: "Artist")
                }
                .padding(.horizontal, 20)

//                if !bandMembers.isEmpty || !profileText.isEmpty {
//                    Divider()
//                        .padding(.horizontal, 20)
//                }
//
//                if !bandMembers.isEmpty {
//                    VStack(alignment: .leading, spacing: 10) {
//                        Text("Members")
//                            .font(.headline)
//
//                        ForEach(Array(bandMembers.enumerated()), id: \.element.id) { index, member in
//                            HStack(spacing: 10) {
//                                Image(systemName: "person.fill")
//                                    .font(.caption)
//                                    .foregroundStyle(.secondary)
//                                Text(member.name)
//                                    .font(.body)
//                                if index == bandMembers.count - 1 {
//                                    Text("Past")
//                                        .font(.caption.weight(.semibold))
//                                        .foregroundStyle(.secondary)
//                                        .padding(.horizontal, 8)
//                                        .padding(.vertical, 3)
//                                        .background(.secondary.opacity(0.15), in: Capsule())
//                                }
//                                Spacer(minLength: 0)
//                            }
//                            .padding(.vertical, 4)
//                        }
//                    }
//                    .padding(.horizontal, 20)
//
//                    if !profileText.isEmpty {
//                        Divider()
//                            .padding(.horizontal, 20)
//                    }
//                }
                
                if let profile = item.profile {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profile")
                            .font(.headline)

                        Text(profile)
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
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.large)
        .task(id: item.id) {
            await fetchArtistDetails()
        }
    }

    @ViewBuilder
    private var artwork: some View {
        if let artworkURL = item.imageUrl ?? item.thumbUrl {
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
        bandMembers.isEmpty ? "Artist" : "Band"
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
        
        do {
            let request = ArtistDetailsRequest.create(artistId: item.id)
            let (data, response) = try await client.send(request)
            let artist = try ArtistDetailMapper.map(data, response, preserving: item)

            await MainActor.run {
                item = artist
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
