import Foundation

enum Config {
    // ⚠️ Replace with your Anthropic API key before shipping.
    // For production: move this call to a backend proxy so the key is never in the binary.
    static let claudeAPIKey = "YOUR_ANTHROPIC_API_KEY_HERE"
    static let claudeModel  = "claude-haiku-4-5-20251001"

    // Free daily scan quota per user
    static let dailyScanLimit = 1

    // App Store & support
    // Replace appStoreID with your real numeric App Store ID once the app is created in App Store Connect.
    static let appStoreID   = "0000000000"
    static let supportEmail = "support@spartanbody.app"
}
