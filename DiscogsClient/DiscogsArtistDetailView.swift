//
//  DiscogsArtistDetailView.swift
//  DiscogsClient
//
//  Created by Codex on 12/02/26.
//

import SwiftUI

struct DiscogsArtistDetailView: View {
    let item: DiscogsSearchResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                artwork
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 12) {
                    Text(item.title)
                        .font(.title2)
                        .fontWeight(.semibold)

                    DetailRow(label: "Type", value: item.type?.capitalized)
                    DetailRow(label: "Country", value: item.country)
                    DetailRow(label: "Year", value: item.year.map(String.init))
                    DetailRow(label: "Discogs ID", value: String(item.id))
                }
            }
            .padding()
        }
        .navigationTitle("Artist Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var artwork: some View {
        AsyncImage(url: item.thumbnailURL) { phase in
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
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.gray.opacity(0.15))
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                }
            @unknown default:
                EmptyView()
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
