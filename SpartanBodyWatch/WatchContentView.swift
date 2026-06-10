import SwiftUI

struct WatchContentView: View {
    @ObservedObject private var store = WatchConnectivityManager.shared
    @ObservedObject private var workout = WatchWorkoutManager.shared
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            WatchDashboardView()
                .tag(0)
            WatchWorkoutView()
                .tag(1)
        }
        .tabViewStyle(.page)
        .onAppear {
            WatchConnectivityManager.shared.activate()
        }
    }
}
