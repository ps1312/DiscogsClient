import SwiftUI

struct ArtistDetailView: View {
    @StateObject private var viewModel: ArtistDetailViewModel
    private let makeArtistAlbumsView: (Int) -> ArtistAlbumsView
    
    init(
        viewModel: ArtistDetailViewModel,
        makeArtistAlbumsView: @escaping (Int) -> ArtistAlbumsView
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeArtistAlbumsView = makeArtistAlbumsView
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AsyncImageWithFallback(url: viewModel.artist.imageUrl ?? viewModel.artist.thumbUrl)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .clipped()

                VStack(alignment: .leading, spacing: 10) {
                    detailRow(label: "Discogs ID", value: String(viewModel.artist.id))
                    detailRow(label: "Type", value: "Artist")
                }
                .padding(.horizontal, 20)

                NavigationLink {
                    makeArtistAlbumsView(viewModel.artist.id)
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

                if let members = viewModel.artist.bandMembers {
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
                
                if let profile = viewModel.artist.profile {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profile")
                            .font(.headline)

                        Text(profile)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 20)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.black)
        .navigationTitle(viewModel.artist.title)
        .navigationBarTitleDisplayMode(.large)
        .task(id: viewModel.artist.id) {
            await viewModel.fetchArtistDetails()
        }
    }

    private func detailRow(label: String, value: String?) -> some View {
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
