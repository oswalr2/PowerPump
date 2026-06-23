import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPrivacy = false

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sbBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {

                        // App icon + name
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(Color.sbAccent.opacity(0.15))
                                    .frame(width: 90, height: 90)
                                Image(systemName: "dumbbell.fill")
                                    .font(.system(size: 40, weight: .semibold))
                                    .foregroundColor(.sbAccent)
                            }
                            Text("PowerPump")
                                .font(SBFont.display(26))
                                .foregroundColor(.sbTextPrimary)
                            Text(appVersion)
                                .font(SBFont.caption())
                                .foregroundColor(.sbTextSecondary)
                        }
                        .padding(.top, 16)

                        // Links card
                        SBCard {
                            VStack(spacing: 0) {
                                aboutRow(icon: "lock.shield.fill", label: "Privacy Policy") {
                                    showPrivacy = true
                                }
                                Divider().background(Color.sbBorder)
                                aboutRow(icon: "star.fill", label: "Rate PowerPump", color: .orange) {
                                    if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(Config.appStoreID)?action=write-review") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                Divider().background(Color.sbBorder)
                                aboutRow(icon: "envelope.fill", label: "Contact Support") {
                                    if let url = URL(string: "mailto:\(Config.supportEmail)?subject=PowerPump%20Support") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }
                        }

                        // AI notice
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(.sbAccent)
                                Text("About AI Features")
                                    .font(SBFont.heading(15))
                                    .foregroundColor(.sbTextPrimary)
                            }
                            Text("The AI Food Scanner uses Claude (by Anthropic). Food photos are sent through our secure server to Anthropic to estimate nutrition; photos are not stored. Everything else — your logs, workouts, and settings — stays on your device.")
                                .font(SBFont.caption())
                                .foregroundColor(.sbTextSecondary)
                                .lineSpacing(4)
                        }
                        .padding(16)
                        .background(Color.sbSurface)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbBorder))

                        Text("© 2026 PowerPump. All rights reserved.")
                            .font(SBFont.label(11))
                            .foregroundColor(Color.sbTextSecondary.opacity(0.5))
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }.foregroundColor(.sbAccent)
                }
            }
        }
        .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
    }

    private func aboutRow(icon: String, label: String, color: Color = .sbAccent, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 22)
                Text(label)
                    .font(SBFont.body())
                    .foregroundColor(.sbTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.sbTextSecondary.opacity(0.4))
            }
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Privacy Policy

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sbBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Last updated: June 2026")
                            .font(SBFont.caption())
                            .foregroundColor(.sbTextSecondary)

                        policySection("Data We Collect",
                            "PowerPump stores all your fitness data (workouts, nutrition logs, goals, measurements) locally on your device only. We do not operate any backend servers or databases.")

                        policySection("AI Features & Third Parties",
                            "When you use the AI Food Scanner or AI Coach, images or text are sent securely to Anthropic's API (claude.ai) to generate responses. Anthropic's privacy policy applies to this data. We do not retain or store these images or AI responses on any server we control.")

                        policySection("Camera & Photos",
                            "Camera and photo access is used exclusively to analyze food for nutrition estimation and to assess exercise form in real time. Images are processed on-device or via Anthropic's API and are never stored by PowerPump.")

                        policySection("Notifications",
                            "If you enable notifications, reminders are scheduled locally on your device using iOS's notification system. No notification data is transmitted to any server.")

                        policySection("Analytics & Tracking",
                            "PowerPump does not use any third-party analytics, advertising SDKs, or tracking tools. We do not track you across apps or websites.")

                        policySection("Data Deletion",
                            "All your data lives on your device. You can delete it at any time by deleting the PowerPump app.")

                        policySection("Contact",
                            "For privacy questions or concerns, contact us at \(Config.supportEmail).")

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }.foregroundColor(.sbAccent)
                }
            }
        }
    }

    private func policySection(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(SBFont.heading(15))
                .foregroundColor(.sbTextPrimary)
            Text(body)
                .font(SBFont.body())
                .foregroundColor(.sbTextSecondary)
                .lineSpacing(4)
        }
    }
}
