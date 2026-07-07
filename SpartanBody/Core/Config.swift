import Foundation

enum Config {
    // Cloudflare Worker proxy for the food scanner. The Anthropic API key lives
    // only on the server — never in the app. Deploy steps: CloudflareWorker/README.md.
    // Replace with your deployed worker URL (must end in /scan).
    static let scanProxyURL = "https://powerpump-scan.TU-SUBDOMINIO.workers.dev/scan"

    // Free weekly scan quota per user. The proxy enforces this server-side;
    // this value only drives the UI. Keep in sync with WEEKLY_LIMIT in worker.js.
    static let weeklyScanLimit = 1

    // App Store & support
    // Replace appStoreID with your real numeric App Store ID once the app is created in App Store Connect.
    static let appStoreID   = "0000000000"
    static let supportEmail = "powerpump.support@gmail.com"
}
