import SwiftUI

struct ChallengesView: View {
    @ObservedObject private var store = ChallengeStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showLibrary = false
    @State private var selectedCategory: ChallengeCategory? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sbBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        if store.active.isEmpty && store.completed.isEmpty {
                            emptyState
                        } else {
                            if !store.active.isEmpty { activeSection }
                            if !store.completed.isEmpty { completedSection }
                        }
                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Challenges")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showLibrary = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.sbAccent)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.sbAccent)
                }
            }
            .onAppear { store.autoCheck() }
        }
        .sheet(isPresented: $showLibrary) { ChallengeLibraryView() }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 60)
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundColor(.sbBorder)
            Text("No Active Challenges")
                .font(SBFont.heading())
                .foregroundColor(.sbTextPrimary)
            Text("Start a challenge to build consistency and earn achievements.")
                .font(SBFont.body())
                .foregroundColor(.sbTextSecondary)
                .multilineTextAlignment(.center)
            SBPrimaryButton(title: "Browse Challenges") { showLibrary = true }
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Active

    private var activeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active (\(store.active.count))")
                .font(SBFont.heading())
                .foregroundColor(.sbTextPrimary)

            ForEach(store.active) { challenge in
                ActiveChallengeCard(challenge: challenge)
            }
        }
    }

    // MARK: - Completed

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed 🏆")
                .font(SBFont.heading())
                .foregroundColor(.sbTextPrimary)

            ForEach(store.completed.prefix(5)) { challenge in
                if let def = challenge.definition {
                    CompletedBadge(definition: def)
                }
            }
        }
    }
}

// MARK: - Active Challenge Card

struct ActiveChallengeCard: View {
    let challenge: ActiveChallenge
    @ObservedObject private var store = ChallengeStore.shared

    private var definition: ChallengeDefinition? { challenge.definition }
    private var todayDone: Bool { challenge.isDayComplete(.now) }

    var body: some View {
        guard let def = definition else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(spacing: 14) {
                // Header
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(def.color.opacity(0.15))
                            .frame(width: 48, height: 48)
                        Image(systemName: def.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(def.color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(def.name)
                            .font(SBFont.heading(16))
                            .foregroundColor(.sbTextPrimary)
                        Text(def.subtitle)
                            .font(SBFont.caption())
                            .foregroundColor(.sbTextSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(challenge.completedDayKeys.count)/\(challenge.totalDays)")
                            .font(SBFont.heading(18))
                            .foregroundColor(def.color)
                        Text("days")
                            .font(SBFont.label(10))
                            .foregroundColor(.sbTextSecondary)
                    }
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.sbBorder).frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(def.color)
                            .frame(width: geo.size.width * challenge.progress, height: 6)
                            .animation(.spring(), value: challenge.progress)
                    }
                }
                .frame(height: 6)

                // Daily dots + action
                HStack(spacing: 6) {
                    // Show last 7 days as dots
                    let last7 = (0..<min(7, challenge.totalDays)).map { offset -> Date in
                        Calendar.current.date(byAdding: .day, value: -offset, to: .now)!
                    }.reversed()

                    ForEach(Array(last7.enumerated()), id: \.offset) { _, date in
                        Circle()
                            .fill(challenge.isDayComplete(date) ? def.color : Color.sbBorder)
                            .frame(width: 10, height: 10)
                    }
                    Spacer()

                    if def.checkType == .manual && !todayDone {
                        Button {
                            store.checkIn(id: challenge.id)
                        } label: {
                            Text("Check In ✓")
                                .font(SBFont.caption())
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(def.color)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    } else if todayDone {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(def.color)
                            Text("Done today!")
                                .font(SBFont.caption())
                                .foregroundColor(def.color)
                        }
                    } else {
                        Text(def.dailyGoalDescription)
                            .font(SBFont.label(11))
                            .foregroundColor(.sbTextSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(16)
            .background(Color.sbSurface)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(def.color.opacity(0.3), lineWidth: 1.5))
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    store.abandon(challenge)
                } label: {
                    Label("Abandon", systemImage: "xmark.circle")
                }
            }
        )
    }
}

// MARK: - Completed Badge

private struct CompletedBadge: View {
    let definition: ChallengeDefinition

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(definition.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: definition.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(definition.color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(definition.name)
                    .font(SBFont.body())
                    .fontWeight(.semibold)
                    .foregroundColor(.sbTextPrimary)
                Text("Completed · \(definition.durationDays) days")
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
            }
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(Color(hex: "#FFD700"))
                .font(.system(size: 20))
        }
        .padding(12)
        .background(Color.sbSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.sbBorder))
    }
}

// MARK: - Library Sheet

struct ChallengeLibraryView: View {
    @ObservedObject private var store = ChallengeStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var filter: ChallengeCategory? = nil

    private var filtered: [ChallengeDefinition] {
        let available = ChallengeLibrary.available(excluding: store.active)
        guard let f = filter else { return available }
        return available.filter { $0.category == f }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sbBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Category filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                filterChip("All", nil)
                                ForEach(ChallengeCategory.allCases, id: \.self) { cat in
                                    filterChip(cat.rawValue, cat)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 4)

                        if filtered.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.sbGreen)
                                Text("All challenges started!")
                                    .font(SBFont.heading())
                                    .foregroundColor(.sbTextPrimary)
                            }
                            .padding(.top, 60)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filtered) { def in
                                    LibraryChallengeRow(definition: def) {
                                        HapticManager.medium()
                                        store.start(def)
                                        dismiss()
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        Spacer(minLength: 32)
                    }
                }
            }
            .navigationTitle("Choose a Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }.foregroundColor(.sbAccent)
                }
            }
        }
    }

    private func filterChip(_ label: String, _ cat: ChallengeCategory?) -> some View {
        Button { withAnimation { filter = cat } } label: {
            Text(label)
                .font(SBFont.caption())
                .foregroundColor(filter == cat ? .white : .sbTextSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(filter == cat ? Color.sbAccent : Color.sbSurface)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.sbBorder))
        }
        .buttonStyle(.plain)
    }
}

private struct LibraryChallengeRow: View {
    let definition: ChallengeDefinition
    let onStart: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(definition.color.opacity(0.12))
                    .frame(width: 50, height: 50)
                Image(systemName: definition.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(definition.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(definition.name)
                    .font(SBFont.heading(15))
                    .foregroundColor(.sbTextPrimary)
                Text(definition.subtitle)
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                    Text("\(definition.durationDays) days")
                }
                .font(SBFont.label(10))
                .foregroundColor(.sbTextSecondary)
            }

            Spacer()

            Button(action: onStart) {
                Text("Start")
                    .font(SBFont.caption())
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(definition.color)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.sbSurface)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sbBorder))
    }
}
