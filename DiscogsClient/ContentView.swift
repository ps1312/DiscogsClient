//
//  ContentView.swift
//  DiscogsClient
//
//  Created by paulo on 12/02/26.
//

import SwiftUI

struct ContentView: View {
    private let token = "gMBGYHrUBKsPAJRDmMTbGCLgHlJrdHbMxlCGOqSM"
    private let userAgent = "DiscogsClient/1.0"

    @State private var searchText = "Nirvana"
    @State private var results: [DiscogsSearchResult] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasSearched = false

    var body: some View {
        NavigationStack {
            VStack {
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                }

                if isLoading, results.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if results.isEmpty, !isLoading, errorMessage == nil {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(.secondary)

                        Text(emptyStateTitle)
                            .font(.title3.weight(.semibold))

                        Text(emptyStateMessage)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    Spacer()
                } else {
                    List(results) { item in
                        NavigationLink {
                            DiscogsArtistDetailView(
                                item: item,
                                token: token,
                                userAgent: userAgent
                            )
                        } label: {
                            HStack(alignment: .center, spacing: 12) {
                                artwork(for: item)
                                    .frame(width: 64, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.title)
                                        .font(.headline)
                                        .lineLimit(2)

                                    Text([item.type?.capitalized, item.country, item.year.map(String.init)]
                                        .compactMap { $0 }
                                        .joined(separator: " • "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer(minLength: 0)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Discogs")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                prompt: "Search for artists..."
            )
        }
        .task(id: searchText) {
            await debouncedSearch()
        }
    }

    @ViewBuilder
    private func artwork(for item: DiscogsSearchResult) -> some View {
        if let thumbnailURL = item.thumbnailURL {
            AsyncImage(url: thumbnailURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else if phase.error != nil {
                    fallbackArtworkIcon
                } else {
                    fallbackArtworkIcon
                }
            }
        } else {
            fallbackArtworkIcon
        }
    }

    private var fallbackArtworkIcon: some View {
        Image(systemName: "person.crop.circle.badge.exclamationmark")
            .font(.system(size: 28, weight: .light))
            .foregroundStyle(.secondary)
    }

    private func debouncedSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !query.isEmpty else {
            await MainActor.run {
                hasSearched = false
                results = []
                errorMessage = nil
                isLoading = false
            }
            return
        }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
            results = []
        }

        do {
            try await Task.sleep(nanoseconds: 500_000_000)
        } catch {
            return
        }

        await fetchDiscogsSearch(query: query)
    }

    private func fetchDiscogsSearch(query: String) async {
        await MainActor.run {
            hasSearched = true
            isLoading = true
            errorMessage = nil
        }

        var components = URLComponents(string: "https://api.discogs.com/database/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "artist"),
            URLQueryItem(name: "per_page", value: "30")
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Discogs token=\(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                guard (200 ... 299).contains(httpResponse.statusCode) else {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "HTTP \(httpResponse.statusCode)"
                    }
                    return
                }
            }

            let decoded = try JSONDecoder().decode(DiscogsSearchResponse.self, from: data)
            await MainActor.run {
                results = decoded.results
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var emptyStateTitle: String {
        if !hasSearched {
            return "Start Searching"
        }

        if !trimmedSearchText.isEmpty {
            return "No Results"
        }

        return "No Recent Searches"
    }

    private var emptyStateMessage: String {
        if !hasSearched {
            return "Find artists on Discogs"
        }

        if !trimmedSearchText.isEmpty {
            return "No matches found for \"\(trimmedSearchText)\""
        }

        return "Your recent searches will appear here"
    }
}

private struct DiscogsSearchResponse: Decodable {
    let results: [DiscogsSearchResult]
}

struct DiscogsSearchResult: Decodable, Identifiable {
    let id: Int
    let title: String
    let type: String?
    let country: String?
    let year: Int?
    let thumb: String?

    var thumbnailURL: URL? {
        guard let thumb, !thumb.isEmpty else { return nil }
        return URL(string: thumb)
    }
}

#Preview {
    ContentView()
}
