struct DiscogsPageMetadata: Decodable {
    let page: Int
    let pages: Int
    let per_page: Int
    let items: Int
}
