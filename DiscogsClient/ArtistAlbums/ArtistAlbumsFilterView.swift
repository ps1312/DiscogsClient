import SwiftUI

struct ArtistAlbumsFilterView: View {
    @ObservedObject var viewModel: ArtistAlbumsViewModel

    @Binding var selectedYear: Int?
    @Binding var selectedLabel: String?

    private var availableYears: [Int] {
        Array(Set(viewModel.paginated.items.compactMap(\.year))).sorted(by: >)
    }

    private var availableLabels: [String] {
        Array(Set(viewModel.paginated.items.compactMap(\.label))).sorted()
    }

    var body: some View {
        HStack(spacing: 8) {
            Menu {
                Button("All Years") { selectedYear = nil }
                ForEach(availableYears, id: \.self) { year in
                    Button(String(year)) { selectedYear = year }
                }
            } label: {
                filterChip(title: selectedYear.map(String.init) ?? "Year")
            }
            .frame(maxWidth: .infinity)

            Menu {
                Button("All Labels") { selectedLabel = nil }
                ForEach(availableLabels, id: \.self) { label in
                    Button(label) { selectedLabel = label }
                }
            } label: {
                filterChip(title: selectedLabel ?? "Label")
            }
            .frame(maxWidth: .infinity)

            Menu {
                Button("All Genres") {}
            } label: {
                filterChip(title: "Genre")
            }
            .frame(maxWidth: .infinity)
            .disabled(true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .animation(.none, value: selectedYear)
        .animation(.none, value: selectedLabel)
    }

    private func filterChip(title: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.down")
                .font(.caption2)
        }
        .font(.subheadline)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(uiColor: .secondarySystemFill), in: Capsule())
    }
}
