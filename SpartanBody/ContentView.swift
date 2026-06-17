import SwiftUI

extension Notification.Name {
    static let switchToTab = Notification.Name("sb.switchToTab")
}

struct ContentView: View {
    @ObservedObject private var profile  = UserProfile.shared
    @ObservedObject private var language = LanguageManager.shared

    var body: some View {
        Group {
            if profile.onboardingDone {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        // The .id() forces SwiftUI to throw away the current view tree and
        // build a fresh one whenever the language changes. Without this,
        // already-rendered Text("...") values keep the old translation.
        .id(language.selectedCode)
        .environment(\.locale, language.locale)
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.sbBackground.ignoresSafeArea()

            Group {
                switch selectedTab {
                case 0: DashboardView()
                case 1: WorkoutsView()
                case 2: ProgressView()
                case 3: RecipesView()
                case 4: ProfileView()
                default: DashboardView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            SBTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .onReceive(NotificationCenter.default.publisher(for: .switchToTab)) { note in
            if let tab = note.object as? Int {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = tab
                }
            }
        }
    }
}

// Using a struct avoids tuple conformance issues in strict Swift
private struct TabItem {
    let icon: String
    let label: String
}

struct SBTabBar: View {
    @Binding var selectedTab: Int

    private let tabs: [TabItem] = [
        TabItem(icon: "house.fill",                    label: "Home"),
        TabItem(icon: "dumbbell.fill",                 label: "Workout"),
        TabItem(icon: "chart.line.uptrend.xyaxis",     label: "Progress"),
        TabItem(icon: "fork.knife",                    label: "Recipes"),
        TabItem(icon: "person.fill",                   label: "Profile"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { i in
                Button {
                    HapticManager.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = i
                    }
                } label: {
                    VStack(spacing: 4) {
                        if i == 2 {
                            ZStack {
                                Circle()
                                    .fill(Color.sbAccent)
                                    .frame(width: 52, height: 52)
                                    .shadow(color: Color.sbAccent.opacity(0.4), radius: 8)
                                Image(systemName: tabs[i].icon)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(y: -12)
                        } else {
                            Image(systemName: tabs[i].icon)
                                .font(.system(size: 20, weight: selectedTab == i ? .bold : .regular))
                                .foregroundColor(selectedTab == i ? .sbAccent : .sbTextSecondary)
                                .scaleEffect(selectedTab == i ? 1.1 : 1.0)

                            Text(LocalizedStringKey(tabs[i].label))
                                .font(SBFont.label(10))
                                .foregroundColor(selectedTab == i ? .sbAccent : .sbTextSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Color.sbSurface
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.sbBorder), alignment: .top)
        )
    }
}
