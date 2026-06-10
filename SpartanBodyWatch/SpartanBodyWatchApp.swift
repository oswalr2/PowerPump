import SwiftUI

@main
struct SpartanBodyWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
        .backgroundTask(.appRefresh("sb.watch.refresh")) {
            await WatchConnectivityManager.shared.requestContextFromPhone()
        }
    }
}

final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        WatchConnectivityManager.shared.activate()
    }
}
