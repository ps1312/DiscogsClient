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

    var body: some View {
        VStack {
            TextField("Search Discogs", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.horizontal)
                .padding(.top, 8)

            if isLoading {
                ProgressView()
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .padding(.horizontal)
            }

            List(results) { item in
                HStack(alignment: .top, spacing: 12) {
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
                .padding(.vertical, 6)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
        }
        .task(id: searchText) {
            await debouncedSearch()
        }
    }

    @ViewBuilder
    private func artwork(for item: DiscogsSearchResult) -> some View {
        AsyncImage(url: item.thumbnailURL) { phase in
            switch phase {
            case .empty:
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.15))
                    ProgressView()
                }
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.15))
                    Image(systemName: "music.note")
                        .foregroundStyle(.secondary)
                }
            @unknown default:
                EmptyView()
            }
        }
    }

    private func debouncedSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !query.isEmpty else {
            await MainActor.run {
                results = []
                errorMessage = nil
                isLoading = false
            }
            return
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
}

private struct DiscogsSearchResponse: Decodable {
    let results: [DiscogsSearchResult]
}

private struct DiscogsSearchResult: Decodable, Identifiable {
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
