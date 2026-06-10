import SwiftUI

struct SettingsView: View {
    @ObservedObject private var theme    = ThemeManager.shared
    @ObservedObject private var language = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showAbout    = false
    @State private var showLanguage = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.sbBackground.ignoresSafeArea()

                List {
                    // MARK: Appearance
                    Section {
                        appearanceRow
                    } header: {
                        sectionHeader("Appearance")
                    }

                    // MARK: Language
                    Section {
                        languageRow
                    } header: {
                        sectionHeader("Language")
                    }

                    // MARK: Support
                    Section {
                        supportRow
                        aboutRow
                    } header: {
                        sectionHeader("Support")
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(Text("Settings"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.sbTextSecondary)
                            .font(.system(size: 20))
                    }
                }
            }
        }
        .sheet(isPresented: $showAbout) { AboutView() }
        .confirmationDialog("", isPresented: $showLanguage, titleVisibility: .hidden) {
            ForEach(LanguageManager.available) { lang in
                Button(lang.flag + " " + lang.nativeName) {
                    language.select(lang.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Appearance row

    private var appearanceRow: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Theme", systemImage: "circle.lefthalf.filled")
                    .foregroundColor(.sbTextPrimary)
                Spacer()
            }
            HStack(spacing: 0) {
                ForEach(AppTheme.allCases, id: \.self) { t in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { theme.current = t }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: t == .dark ? "moon.fill" : "sun.max.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text(LocalizedStringKey(t.rawValue))
                                .font(SBFont.caption())
                        }
                        .foregroundColor(theme.current == t ? .white : .sbTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(theme.current == t ? Color.sbAccent : Color.clear)
                        .cornerRadius(9)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Color.sbSurfaceRaised)
            .cornerRadius(12)
        }
        .padding(.vertical, 6)
        .listRowBackground(Color.sbSurface)
    }

    // MARK: - Language row

    private var languageRow: some View {
        Button {
            showLanguage = true
        } label: {
            HStack {
                Label("Language", systemImage: "globe")
                    .foregroundColor(.sbTextPrimary)
                Spacer()
                Text(language.currentLanguage.flag + " " + language.currentLanguage.nativeName)
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.sbTextSecondary.opacity(0.5))
            }
        }
        .listRowBackground(Color.sbSurface)
    }

    // MARK: - Support rows

    private var supportRow: some View {
        Button {
            let email = Config.supportEmail
            if let url = URL(string: "mailto:\(email)") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack {
                Label("Contact Support", systemImage: "envelope.fill")
                    .foregroundColor(.sbTextPrimary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.sbTextSecondary.opacity(0.5))
            }
        }
        .listRowBackground(Color.sbSurface)
    }

    private var aboutRow: some View {
        Button {
            showAbout = true
        } label: {
            HStack {
                Label("About & Privacy", systemImage: "info.circle.fill")
                    .foregroundColor(.sbTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.sbTextSecondary.opacity(0.5))
            }
        }
        .listRowBackground(Color.sbSurface)
    }

    // MARK: - Helpers

    private func sectionHeader(_ key: String) -> some View {
        Text(LocalizedStringKey(key))
            .font(SBFont.label(12))
            .foregroundColor(.sbTextSecondary)
            .textCase(nil)
    }
}
