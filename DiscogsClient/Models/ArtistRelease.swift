import Foundation

struct ArtistRelease: Decodable, Identifiable {
    let id: Int
    let title: String
    let year: Int?
    let thumb: String?
    let format: String?
    let type: String?
    let label: String?
    let artist: String?

    var thumbnailURL: URL? {
        guard let thumb, !thumb.isEmpty else { return nil }
        return URL(string: thumb)
    }
}
