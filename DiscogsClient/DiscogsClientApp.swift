//
//  DiscogsClientApp.swift
//  DiscogsClient
//
//  Created by paulo on 12/02/26.
//

import SwiftUI

@main
struct DiscogsClientApp: App {
    private let client: HTTPClient = URLSession.shared

    var body: some Scene {
        WindowGroup {
            ArtistSearchView(
                viewModel: ArtistSearchViewModel(client: client),
                makeArtistDetailView: makeArtistDetailView
            )
        }
    }

    private func makeArtistDetailView(_ artist: Artist) -> ArtistDetailView {
        ArtistDetailView(
            viewModel: ArtistDetailViewModel(client: client, existing: artist),
            makeArtistAlbumsView: makeArtistAlbumsView
        )
    }

    private func makeArtistAlbumsView(_ artistID: Int, _ artistName: String) -> ArtistAlbumsView {
        ArtistAlbumsView(
            viewModel: ArtistAlbumsViewModel(
                client: client,
                artistID: artistID,
                selectedArtistName: artistName
            )
        )
    }
}
