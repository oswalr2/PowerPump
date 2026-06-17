import SwiftUI

// Quick post-onboarding walkthrough so new users know where everything lives.
// Shown once (gated on the "sb_tutorial_done" flag) and respects whatever
// language the user picked, because LanguageManager already overrides
// Bundle.main at runtime.
struct TutorialView: View {
    let onFinish: () -> Void

    @State private var page = 0
    @State private var appeared = false

    private struct Step {
        let icon: String
        let iconColor: Color
        let title: String      // localized key
        let body: String       // localized key
        let highlight: String  // a small hint like "Bottom bar"
    }

    private let steps: [Step] = [
        .init(icon: "bolt.fill",
              iconColor: .sbAccent,
              title: "tutorial.welcome.title",
              body:  "tutorial.welcome.body",
              highlight: "tutorial.welcome.hint"),

        .init(icon: "house.fill",
              iconColor: .sbAccent,
              title: "tutorial.dashboard.title",
              body:  "tutorial.dashboard.body",
              highlight: "tutorial.dashboard.hint"),

        .init(icon: "dumbbell.fill",
              iconColor: .sbAccent,
              title: "tutorial.workout.title",
              body:  "tutorial.workout.body",
              highlight: "tutorial.workout.hint"),

        .init(icon: "fork.knife",
              iconColor: .sbAccent,
              title: "tutorial.nutrition.title",
              body:  "tutorial.nutrition.body",
              highlight: "tutorial.nutrition.hint"),

        .init(icon: "sparkles",
              iconColor: .sbAccent,
              title: "tutorial.coach.title",
              body:  "tutorial.coach.body",
              highlight: "tutorial.coach.hint"),

        .init(icon: "checkmark.circle.fill",
              iconColor: .sbGreen,
              title: "tutorial.ready.title",
              body:  "tutorial.ready.body",
              highlight: ""),
    ]

    var body: some View {
        ZStack {
            Color.sbBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                pages
                bottomBar
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                appeared = true
            }
        }
    }

    // MARK: - Top bar (Skip)

    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                HapticManager.light()
                finish()
            } label: {
                Text("tutorial.skip")
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.sbSurfaceRaised)
                    .cornerRadius(14)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .opacity(page == steps.count - 1 ? 0 : 1)   // hide on the last step
        .animation(.easeOut(duration: 0.2), value: page)
    }

    // MARK: - Pages

    private var pages: some View {
        TabView(selection: $page) {
            ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                stepView(step)
                    .tag(idx)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private func stepView(_ step: Step) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon hero
            ZStack {
                Circle()
                    .fill(step.iconColor.opacity(0.15))
                    .frame(width: 140, height: 140)
                Circle()
                    .stroke(LinearGradient.sbAccentGradient, lineWidth: 3)
                    .frame(width: 150, height: 150)
                    .shadow(color: step.iconColor.opacity(0.4), radius: 12)
                Image(systemName: step.icon)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundColor(step.iconColor)
            }
            .padding(.bottom, 8)

            VStack(spacing: 12) {
                Text(LocalizedStringKey(step.title))
                    .font(SBFont.display(28))
                    .foregroundColor(.sbTextPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(LocalizedStringKey(step.body))
                    .font(SBFont.body())
                    .foregroundColor(.sbTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 28)

            if !step.highlight.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text(LocalizedStringKey(step.highlight))
                        .font(SBFont.caption())
                }
                .foregroundColor(.sbAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.sbAccentDim)
                .cornerRadius(12)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Bottom bar (dots + next/start)

    private var bottomBar: some View {
        VStack(spacing: 18) {
            // Page dots
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? Color.sbAccent : Color.sbBorder)
                        .frame(width: i == page ? 22 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.25), value: page)
                }
            }

            SBPrimaryButton(title: page == steps.count - 1
                            ? "tutorial.start" : "tutorial.next") {
                HapticManager.light()
                if page == steps.count - 1 {
                    finish()
                } else {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        page += 1
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 32)
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: "sb_tutorial_done")
        withAnimation(.easeInOut(duration: 0.35)) {
            onFinish()
        }
    }
}
