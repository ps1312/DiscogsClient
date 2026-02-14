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
                makeArtistDetailView: { artist in
                    ArtistDetailView(
                        viewModel: ArtistDetailViewModel(client: client, existing: artist),
                        makeArtistAlbumsView: { ArtistAlbumsView(client: client, artistID: $0) }
                    )
                }
            )
        }
    }
}
