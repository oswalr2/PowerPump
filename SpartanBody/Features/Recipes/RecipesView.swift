import SwiftUI

struct RecipesView: View {
    @ObservedObject private var profile = UserProfile.shared
    @State private var selectedGoal: RecipeGoal? = nil
    @State private var searchText = ""

    private var filtered: [Recipe] {
        var list = RecipeDatabase.all
        if let g = selectedGoal { list = list.filter { $0.goal == g } }
        if !searchText.isEmpty { list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) } }
        return list
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sbBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        header
                        goalFilter
                        if filtered.isEmpty { emptyState }
                        else { recipeGrid }
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 16)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recipes")
                        .font(SBFont.display(28))
                        .foregroundColor(.sbTextPrimary)
                    Text("For your goal: \(NSLocalizedString(profile.goal.rawValue, comment: ""))")
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundColor(.sbTextSecondary)
                TextField("Search recipes…", text: $searchText)
                    .font(SBFont.body())
                    .foregroundColor(.sbTextPrimary)
            }
            .padding(12)
            .background(Color.sbSurface)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.sbBorder))
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Goal filter

    private var goalFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                goalChip(nil, label: "All")
                ForEach(RecipeGoal.allCases, id: \.self) { g in
                    goalChip(g, label: g.rawValue)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func goalChip(_ goal: RecipeGoal?, label: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedGoal = goal }
        } label: {
            Text(LocalizedStringKey(label))
                .font(SBFont.caption())
                .foregroundColor(selectedGoal == goal ? .white : .sbTextSecondary)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(selectedGoal == goal ? Color.sbAccent : Color.sbSurface)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(selectedGoal == goal ? Color.sbAccent : Color.sbBorder))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recipe grid

    private var recipeGrid: some View {
        LazyVStack(spacing: 14) {
            ForEach(filtered) { recipe in
                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                    RecipeCard(recipe: recipe)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("🍽️")
                .font(.system(size: 48))
            Text("No recipes found")
                .font(SBFont.heading(18))
                .foregroundColor(.sbTextSecondary)
        }
        .padding(.top, 40)
    }
}

// MARK: - Recipe Card

private struct RecipeCard: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 14) {
            Text(recipe.emoji)
                .font(.system(size: 40))
                .frame(width: 64, height: 64)
                .background(Color.sbSurfaceRaised)
                .cornerRadius(16)

            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.name)
                    .font(SBFont.heading(16))
                    .foregroundColor(.sbTextPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Label("\(recipe.prepMinutes) min", systemImage: "clock")
                    Circle().fill(Color.sbBorder).frame(width: 3, height: 3)
                    Label("\(Int(recipe.nutrition.calories)) kcal", systemImage: "flame")
                    Circle().fill(Color.sbBorder).frame(width: 3, height: 3)
                    Label("\(recipe.servings) serving\(recipe.servings > 1 ? "s" : "")", systemImage: "person")
                }
                .font(SBFont.label(10))
                .foregroundColor(.sbTextSecondary)
                .labelStyle(.titleAndIcon)

                HStack(spacing: 6) {
                    GoalBadge(goal: recipe.goal)
                    ForEach(recipe.tags.prefix(2), id: \.self) { tag in
                        TagBadge(text: tag)
                    }
                }
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.sbBorder)
        }
        .padding(14)
        .background(Color.sbSurface)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.sbBorder))
    }
}

private struct GoalBadge: View {
    let goal: RecipeGoal
    private var color: Color {
        switch goal {
        case .muscleGain:  return .sbAccent
        case .weightLoss:  return Color(hex: "#FF375F")
        case .maintenance: return .sbGreen
        }
    }
    var body: some View {
        Text(LocalizedStringKey(goal.rawValue))
            .font(SBFont.label(9))
            .foregroundColor(color)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(color.opacity(0.15))
            .cornerRadius(5)
    }
}

private struct TagBadge: View {
    let text: String
    var body: some View {
        Text(LocalizedStringKey(text))
            .font(SBFont.label(9))
            .foregroundColor(.sbTextSecondary)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Color.sbSurfaceRaised)
            .cornerRadius(5)
    }
}

// MARK: - Recipe Detail

struct RecipeDetailView: View {
    let recipe: Recipe
    @ObservedObject private var foodLog = FoodLogStore.shared
    @State private var servings: Double = 1
    @State private var loggedToast = false
    @Environment(\.dismiss) private var dismiss

    private var scaled: NutritionInfo {
        recipe.nutrition.scaled(by: servings)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.sbBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Hero
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.sbSurface)
                            .frame(height: 160)
                        Text(recipe.emoji)
                            .font(.system(size: 80))
                    }
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(recipe.name)
                            .font(SBFont.display(26))
                            .foregroundColor(.sbTextPrimary)

                        HStack(spacing: 12) {
                            Label("\(recipe.prepMinutes) min", systemImage: "clock")
                            Label("\(recipe.servings) serving\(recipe.servings > 1 ? "s" : "")", systemImage: "person.2")
                            GoalBadge(goal: recipe.goal)
                        }
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                        .labelStyle(.titleAndIcon)
                    }
                    .padding(.horizontal, 20)

                    // Nutrition macros
                    nutritionSection

                    // Ingredients
                    sectionHeader("Ingredients")
                    VStack(spacing: 10) {
                        ForEach(recipe.ingredients) { ing in
                            HStack {
                                Circle().fill(Color.sbAccent).frame(width: 6, height: 6)
                                Text(ing.name)
                                    .font(SBFont.body())
                                    .foregroundColor(.sbTextPrimary)
                                Spacer()
                                Text(ing.amount)
                                    .font(SBFont.caption())
                                    .foregroundColor(.sbTextSecondary)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.sbSurface)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbBorder))
                    .padding(.horizontal, 20)

                    // Steps
                    sectionHeader("Instructions")
                    VStack(spacing: 14) {
                        ForEach(Array(recipe.steps.enumerated()), id: \.offset) { i, step in
                            HStack(alignment: .top, spacing: 14) {
                                Text("\(i + 1)")
                                    .font(SBFont.label())
                                    .foregroundColor(.white)
                                    .frame(width: 26, height: 26)
                                    .background(Color.sbAccent)
                                    .clipShape(Circle())
                                Text(step)
                                    .font(SBFont.body())
                                    .foregroundColor(.sbTextPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.sbSurface)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbBorder))
                    .padding(.horizontal, 20)

                    Spacer(minLength: 120)
                }
                .padding(.top, 16)
            }

            // Log to nutrition button
            logButton
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .top) { backButton }
        .overlay {
            if loggedToast {
                toastView
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Nutrition section

    private var nutritionSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Nutrition")
                    .font(SBFont.heading())
                    .foregroundColor(.sbTextPrimary)
                Spacer()
                Stepper(value: $servings, in: 0.5...5, step: 0.5) {
                    Text("\(servings, specifier: "%.1f") serving\(servings > 1 ? "s" : "")")
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                }
                .fixedSize()
            }

            HStack(spacing: 0) {
                macroStat("Calories", "\(Int(scaled.calories))", "kcal")
                Divider().frame(height: 40)
                macroStat("Protein",  String(format: "%.0fg", scaled.protein),  "")
                Divider().frame(height: 40)
                macroStat("Carbs",    String(format: "%.0fg", scaled.carbs),    "")
                Divider().frame(height: 40)
                macroStat("Fat",      String(format: "%.0fg", scaled.fat),      "")
            }
            .padding(14)
            .background(Color.sbSurface)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbBorder))
        }
        .padding(.horizontal, 20)
    }

    private func macroStat(_ label: String, _ value: String, _ unit: String) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(SBFont.heading(18)).foregroundColor(.sbTextPrimary)
                if !unit.isEmpty { Text(unit).font(SBFont.label()).foregroundColor(.sbTextSecondary) }
            }
            Text(label).font(SBFont.label(10)).foregroundColor(.sbTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(SBFont.heading())
            .foregroundColor(.sbTextPrimary)
            .padding(.horizontal, 20)
    }

    // MARK: - Log button

    private var logButton: some View {
        Button {
            let item = FoodItem(
                id: recipe.id,
                name: recipe.name,
                category: .other,
                per100g: NutritionInfo(
                    calories: scaled.calories,
                    protein:  scaled.protein,
                    carbs:    scaled.carbs,
                    fat:      scaled.fat
                )
            )
            foodLog.add(item, grams: 100, meal: .dinner)
            withAnimation(.spring(response: 0.4)) { loggedToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { loggedToast = false }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("Log to Nutrition")
                    .fontWeight(.bold)
            }
            .font(SBFont.body())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.sbAccent)
            .cornerRadius(16)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .buttonStyle(.plain)
        .background(Color.sbBackground.opacity(0.95).ignoresSafeArea())
    }

    private var backButton: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.sbTextPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.sbSurface.opacity(0.9))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.sbBorder))
            }
            .padding(.leading, 20)
            .padding(.top, 8)
            Spacer()
        }
    }

    private var toastView: some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.sbGreen)
                Text("Logged to Dinner")
                    .font(SBFont.body())
                    .foregroundColor(.sbTextPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.sbSurface)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sbBorder))
            .padding(.top, 60)
            Spacer()
        }
    }
}

// MARK: - Recipe Identifiable for navigationDestination

extension Recipe: Hashable {
    static func == (lhs: Recipe, rhs: Recipe) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
