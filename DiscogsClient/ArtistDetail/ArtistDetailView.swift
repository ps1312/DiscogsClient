import SwiftUI

struct ArtistDetailView: View {
    let client: HTTPClient

    @State private var item: Artist
    @State private var artist: ArtistDetailMapper.DiscogsArtistDetailResult?
    @State private var isLoadingArtist = false
    @State private var errorMessage: String?
    
    init(client: HTTPClient, item: Artist) {
        self.client = client
        _item = State(initialValue: item)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AsyncImageWithFallback(url: item.imageUrl ?? item.thumbUrl)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .clipped()

                VStack(alignment: .leading, spacing: 10) {
                    DetailRow(label: "Discogs ID", value: String(item.id))
                    DetailRow(label: "Type", value: "Artist")
                }
                .padding(.horizontal, 20)

                NavigationLink {
                    ArtistAlbumsView(client: client, artistID: item.id)
                        .navigationTitle("Albums")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    Label("View Albums", systemImage: "opticaldisc")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 20)

                if let members = item.bandMembers {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Members")
                            .font(.headline)

                        ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                            HStack(spacing: 10) {
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Text(member.name)
                                    .font(.body)
                                
                                if !member.active {
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
                }
                
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

    private var displayType: String {
        bandMembers.isEmpty ? "Artist" : "Band"
    }

    private var bandMembers: [BandMember] {
        guard let members = artist?.members else { return [] }
        return members.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func fetchArtistDetails() async {
        await MainActor.run {
            isLoadingArtist = true
            errorMessage = nil
        }
        
        do {
            let request = ApiRequestBuilder.details(for: item.id)
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
