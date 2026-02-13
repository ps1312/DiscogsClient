import Foundation

struct Artist: Identifiable {
    let id: Int
    let title: String
    let thumbUrl: URL?
    let imageUrl: URL?
    let profile: String?
}
