struct DiscogsPageMetadata: Decodable {
    let page: Int
    let pages: Int
    let perPage: Int
    let items: Int

    private enum CodingKeys: String, CodingKey {
        case page
        case pages
        case perPage = "per_page"
        case items
    }
}
