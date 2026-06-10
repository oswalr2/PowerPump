import SwiftUI

struct ExercisesView: View {
    @State private var selectedCategory: MuscleGroup? = nil
    @State private var selectedLocation: ExerciseLocation = .both
    @State private var searchText = ""
    @State private var showSearch = false

    private var filtered: [Exercise] {
        var list = ExerciseDatabase.all
        if let cat = selectedCategory { list = list.filter { $0.category == cat } }
        if selectedLocation != .both { list = list.filter { $0.location == selectedLocation || $0.location == .both } }
        if !searchText.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return list
    }

    var body: some View {
        ZStack {
            Color.sbBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Exercises")
                        .font(SBFont.display(28))
                        .foregroundColor(.sbTextPrimary)
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3)) { showSearch.toggle() }
                    } label: {
                        Image(systemName: showSearch ? "xmark" : "magnifyingglass")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.sbTextSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Search bar
                if showSearch {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.sbTextSecondary)
                        TextField("Search exercises...", text: $searchText)
                            .font(SBFont.body())
                            .foregroundColor(.sbTextPrimary)
                    }
                    .padding(12)
                    .background(Color.sbSurface)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.sbBorder))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Location filter
                HStack(spacing: 8) {
                    ForEach([ExerciseLocation.both, .gym, .home], id: \.self) { loc in
                        Button {
                            withAnimation(.spring(response: 0.25)) { selectedLocation = loc }
                        } label: {
                            Text(loc == .both ? "All" : loc.rawValue)
                                .font(SBFont.caption())
                                .foregroundColor(selectedLocation == loc ? .white : .sbTextSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(selectedLocation == loc ? Color.sbAccent : Color.sbSurface)
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.sbBorder, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // Category scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        CategoryChip(label: "All", icon: "square.grid.2x2.fill", isSelected: selectedCategory == nil) {
                            withAnimation(.spring(response: 0.25)) { selectedCategory = nil }
                        }
                        ForEach(MuscleGroup.allCases, id: \.self) { group in
                            CategoryChip(label: group.rawValue, icon: group.icon, isSelected: selectedCategory == group) {
                                withAnimation(.spring(response: 0.25)) {
                                    selectedCategory = selectedCategory == group ? nil : group
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 16)

                // Exercise list
                if filtered.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.sbTextSecondary)
                        Text("No exercises found")
                            .font(SBFont.heading(18))
                            .foregroundColor(.sbTextSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(filtered) { exercise in
                                NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                    ExerciseRow(exercise: exercise)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(label)
                    .font(SBFont.caption())
            }
            .foregroundColor(isSelected ? .white : .sbTextSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.sbAccent : Color.sbSurface)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? Color.sbAccent : Color.sbBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Exercise Row

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 14) {
            // Muscle icon thumbnail
            Group {
                if let name = ExerciseDatabase.muscleIconNames[exercise.id],
                   let img = UIImage(named: name) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    MuscleBodyView(category: exercise.category, secondaryMuscles: exercise.secondaryMuscles)
                }
            }
            .frame(width: 44, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .background(Color.sbSurfaceRaised)
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(SBFont.heading(16))
                    .foregroundColor(.sbTextPrimary)

                HStack(spacing: 6) {
                    Text(exercise.primaryMuscle)
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)

                    Circle()
                        .fill(Color.sbBorder)
                        .frame(width: 3, height: 3)

                    Text(exercise.equipment.rawValue)
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                }

                HStack(spacing: 6) {
                    DifficultyBadge(difficulty: exercise.difficulty)
                    if exercise.location == .home || exercise.location == .both {
                        LocationBadge(label: "Home")
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.sbBorder)
        }
        .padding(14)
        .background(Color.sbSurface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbBorder, lineWidth: 1))
    }
}

struct DifficultyBadge: View {
    let difficulty: Difficulty

    private var color: Color {
        switch difficulty {
        case .beginner: return .sbGreen
        case .intermediate: return .sbAccent
        case .advanced: return .sbRed
        }
    }

    var body: some View {
        Text(difficulty.rawValue)
            .font(SBFont.label(10))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .cornerRadius(6)
    }
}

struct LocationBadge: View {
    let label: String

    var body: some View {
        Text(label)
            .font(SBFont.label(10))
            .foregroundColor(.sbTextSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.sbSurfaceRaised)
            .cornerRadius(6)
    }
}
