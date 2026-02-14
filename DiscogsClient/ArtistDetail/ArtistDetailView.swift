import SwiftUI

struct ArtistDetailView: View {
    @StateObject private var viewModel: ArtistDetailViewModel
    private let makeArtistAlbumsView: (Int, String) -> ArtistAlbumsView

    init(
        viewModel: ArtistDetailViewModel,
        makeArtistAlbumsView: @escaping (Int, String) -> ArtistAlbumsView
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeArtistAlbumsView = makeArtistAlbumsView
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Color.clear
                    .frame(height: 250)
                    .overlay {
                        AsyncImageWithFallback(url: viewModel.artist.imageUrl ?? viewModel.artist.thumbUrl)
                            .aspectRatio(contentMode: .fill)
                    }
                    .background(Color(uiColor: .secondarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .clipped()
                    .padding(.horizontal, 20)

                NavigationLink {
                    makeArtistAlbumsView(viewModel.artist.id, viewModel.artist.title)
                        .navigationTitle("Albums")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "opticaldisc")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.blue, in: Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text("View Albums")
                                .font(.headline)
                            Text("Browse releases and filters")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        Color(uiColor: .secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 10) {
                    detailRow(label: "Discogs ID", value: String(viewModel.artist.id))
                    detailRow(label: "Type", value: viewModel.artistType)
                }
                .padding(.horizontal, 20)

                if let members = viewModel.orderedBandMembers {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Members")
                            .font(.headline)

                        ForEach(members) { member in
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

                if let profile = viewModel.artist.profile, !profile.isEmpty {
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
                    HStack {
                        Spacer()
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 20)
                        Spacer()
                    }
                }

                if viewModel.isLoadingArtist {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
        }
        .navigationTitle(viewModel.artist.title)
        .navigationBarTitleDisplayMode(.large)
        .task(id: viewModel.artist.id) {
            await viewModel.fetchArtistDetailsIfNeeded()
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
