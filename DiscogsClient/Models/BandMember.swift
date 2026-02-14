import Foundation

struct BandMember: Decodable, Identifiable {
    let id: Int
    let name: String
    let active: Bool
}
