import SwiftUI

struct WatchlistView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Watchlist is empty",
                systemImage: "star",
                description: Text("Watchlist storage and synchronization will be added in a later stage.")
            )
            .navigationTitle("Watchlist")
        }
    }
}
