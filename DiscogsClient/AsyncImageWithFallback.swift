import SwiftUI

struct AsyncImageWithFallback: View {
    let url: URL?

    var placeholder: some View {
        Image(systemName: "person.crop.circle.badge.exclamationmark")
            .font(.system(size: 28, weight: .light))
            .foregroundStyle(.secondary)
    }

    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else if phase.error != nil {
                    placeholder
                } else {
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }
}
