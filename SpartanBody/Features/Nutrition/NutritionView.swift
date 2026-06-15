import SwiftUI
import Charts

struct NutritionView: View {
    @ObservedObject private var store   = FoodLogStore.shared
    @ObservedObject private var profile = UserProfile.shared

    @State private var addingMeal:    MealType?
    @State private var showFoodScanner = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sbBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        header
                        calorieCard
                        if store.todayEntries.isEmpty && !store.yesterdayEntries.isEmpty {
                            copyYesterdayButton
                        }
                        macrosCard
                        weeklyCard
                        ForEach(MealType.allCases, id: \.self) { meal in
                            MealSection(meal: meal, addingMeal: $addingMeal)
                        }
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $addingMeal) { meal in
            FoodSearchView(meal: meal)
        }
        .sheet(isPresented: $showFoodScanner) {
            FoodScannerView()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Nutrition")
                    .font(SBFont.display(28))
                    .foregroundColor(.sbTextPrimary)
                Text(todayString)
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
            }
            Spacer()
            HStack(spacing: 14) {
                Button { showFoodScanner = true } label: {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.sbAccent)
                }
                Button { addingMeal = .snack } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.sbAccent)
                }
            }
        }
    }

    private var todayString: String {
        let f = DateFormatter()
        f.dateStyle = .full
        return f.string(from: .now)
    }

    // MARK: - Copy yesterday

    private var copyYesterdayButton: some View {
        Button {
            HapticManager.success()
            withAnimation(.spring(response: 0.4)) { store.copyYesterday() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.sbAccent)
                Text("Copy yesterday's meals")
                    .font(SBFont.body())
                    .fontWeight(.semibold)
                    .foregroundColor(.sbTextPrimary)
                Spacer()
                Text("\(Int(store.yesterdayEntries.reduce(0) { $0 + $1.nutrition.calories })) kcal")
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
            }
            .padding(14)
            .background(Color.sbAccentDim)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sbAccent.opacity(0.35)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Calorie card

    private var calorieCard: some View {
        let goal      = Double(profile.dailyCalorieTarget)
        let consumed  = store.todayCalories
        let remaining = max(0, goal - consumed)
        let progress  = min(1, consumed / max(1, goal))
        let over      = progress >= 1

        return VStack(spacing: 16) {
            HStack {
                Text("Calories")
                    .font(SBFont.heading())
                    .foregroundColor(.sbTextPrimary)
                Spacer()
                Text("Goal: \(profile.dailyCalorieTarget) kcal")
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
            }

            HStack(alignment: .center, spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color.sbSurfaceRaised, lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            over ? AnyShapeStyle(Color.sbRed)
                                 : AnyShapeStyle(AngularGradient(
                                       colors: [.sbAccent, .sbCyan, .sbAccent],
                                       center: .center, startAngle: .degrees(-90), endAngle: .degrees(270))),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Color.sbAccent.opacity(consumed > 0 ? 0.3 : 0), radius: 6)
                        .animation(.spring(response: 0.6), value: consumed)
                    VStack(spacing: 2) {
                        Text("\(Int(consumed))")
                            .font(SBFont.heading(22))
                            .foregroundColor(.sbTextPrimary)
                        Text("kcal")
                            .font(SBFont.label())
                            .foregroundColor(.sbTextSecondary)
                    }
                }
                .frame(width: 110, height: 110)

                VStack(alignment: .leading, spacing: 12) {
                    calorieStat("Consumed",  "\(Int(consumed)) kcal",  .sbAccent)
                    calorieStat("Remaining", "\(Int(remaining)) kcal", over ? .sbRed : .sbTextPrimary)
                    calorieStat("Goal",      "\(profile.dailyCalorieTarget) kcal", .sbTextSecondary)
                }
                Spacer()
            }
        }
        .padding(18)
        .background(Color.sbSurface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.sbBorder))
    }

    private func calorieStat(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(LocalizedStringKey(label)).font(SBFont.label()).foregroundColor(.sbTextSecondary)
            Text(value).font(SBFont.body()).fontWeight(.semibold).foregroundColor(color)
        }
    }

    // MARK: - Macros card

    private var macrosCard: some View {
        let pGoal = Double(profile.dailyProteinTarget)
        let cGoal = Double(profile.dailyCalorieTarget) * 0.45 / 4
        let fGoal = Double(profile.dailyCalorieTarget) * 0.25 / 9

        return VStack(spacing: 14) {
            Text("Macros")
                .font(SBFont.heading())
                .foregroundColor(.sbTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            MacroBar(label: "Protein", value: store.todayProtein, goal: pGoal, color: Color.sbAccent)
            MacroBar(label: "Carbs",   value: store.todayCarbs,   goal: cGoal, color: Color(hex: "#FF9F0A"))
            MacroBar(label: "Fat",     value: store.todayFat,     goal: fGoal, color: Color(hex: "#FF375F"))
        }
        .padding(18)
        .background(Color.sbSurface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.sbBorder))
    }

    // MARK: - Weekly card

    private var weeklyCard: some View {
        let data = store.weeklyMacros()
        let avgCal = data.filter { $0.calories > 0 }.map(\.calories)
        let avg = avgCal.isEmpty ? 0 : avgCal.reduce(0, +) / Double(avgCal.count)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("This Week")
                    .font(SBFont.heading())
                    .foregroundColor(.sbTextPrimary)
                Spacer()
                if avg > 0 {
                    Text("Avg \(Int(avg)) kcal")
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                }
            }

            Chart {
                ForEach(data, id: \.date) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Protein", day.protein)
                    )
                    .foregroundStyle(Color.sbAccent.gradient)
                    .position(by: .value("Macro", "Protein"))
                    .cornerRadius(3)

                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Carbs", day.carbs)
                    )
                    .foregroundStyle(Color(hex: "#FF9F0A").gradient)
                    .position(by: .value("Macro", "Carbs"))
                    .cornerRadius(3)

                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Fat", day.fat)
                    )
                    .foregroundStyle(Color(hex: "#FF375F").gradient)
                    .position(by: .value("Macro", "Fat"))
                    .cornerRadius(3)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .foregroundStyle(Color.sbTextSecondary)
                        .font(SBFont.label(10))
                }
            }
            .chartYAxis {
                AxisMarks { v in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.sbBorder)
                    AxisValueLabel {
                        if let val = v.as(Double.self) {
                            Text("\(Int(val))g")
                                .foregroundStyle(Color.sbTextSecondary)
                                .font(SBFont.label(10))
                        }
                    }
                }
            }
            .chartLegend(position: .bottom, alignment: .leading, spacing: 8) {
                HStack(spacing: 14) {
                    legendDot(Color.sbAccent, "Protein")
                    legendDot(Color(hex: "#FF9F0A"), "Carbs")
                    legendDot(Color(hex: "#FF375F"), "Fat")
                }
                .font(SBFont.label(10))
                .foregroundColor(.sbTextSecondary)
            }
            .frame(height: 130)
        }
        .padding(18)
        .background(Color.sbSurface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.sbBorder))
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(LocalizedStringKey(label))
        }
    }
}

// MARK: - Macro Bar

private struct MacroBar: View {
    let label: String
    let value: Double
    let goal:  Double
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(LocalizedStringKey(label)).font(SBFont.caption()).foregroundColor(.sbTextSecondary)
                Spacer()
                Text(String(format: "%.0fg / %.0fg", value, goal))
                    .font(SBFont.label()).foregroundColor(.sbTextPrimary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.sbBorder).frame(height: 7)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * min(1, value / max(1, goal)), height: 7)
                        .animation(.spring(response: 0.5), value: value)
                }
            }
            .frame(height: 7)
        }
    }
}

// MARK: - Meal Section

private struct MealSection: View {
    let meal: MealType
    @Binding var addingMeal: MealType?
    @ObservedObject private var store = FoodLogStore.shared
    @State private var showSaveMeal = false
    @State private var savedMealName = ""

    var body: some View {
        let entries = store.entries(for: meal)
        let kcal    = store.calories(for: meal)

        return VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: meal.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.sbAccent)
                Text(LocalizedStringKey(meal.rawValue))
                    .font(SBFont.heading(15))
                    .foregroundColor(.sbTextPrimary)
                Spacer()
                if kcal > 0 {
                    Text("\(Int(kcal)) kcal")
                        .font(SBFont.caption()).foregroundColor(.sbTextSecondary)
                }
                if !entries.isEmpty {
                    Button {
                        savedMealName = ""
                        showSaveMeal = true
                    } label: {
                        Image(systemName: "bookmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.sbAccent)
                    }
                    .buttonStyle(.plain)
                }
                Button { addingMeal = meal } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.sbAccent)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .alert("Save as meal", isPresented: $showSaveMeal) {
                TextField("Meal name…", text: $savedMealName)
                Button("Save") {
                    let name = savedMealName.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty else { return }
                    SavedMealStore.shared.save(name: name, entries: entries)
                    HapticManager.success()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Log this combo again with one tap from the food search.")
            }

            if entries.isEmpty {
                Text("Tap + to log food")
                    .font(SBFont.caption())
                    .foregroundColor(Color.sbTextSecondary.opacity(0.5))
                    .padding(.bottom, 14)
            } else {
                Divider().background(Color.sbBorder)
                ForEach(entries) { entry in FoodEntryRow(entry: entry) }
            }
        }
        .background(Color.sbSurface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbBorder))
    }
}

// MARK: - Food Entry Row

private struct FoodEntryRow: View {
    let entry: LoggedFood
    @ObservedObject private var store = FoodLogStore.shared

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(entry.foodName))
                    .font(SBFont.body()).foregroundColor(.sbTextPrimary)
                Text(String(format: "%.0fg", entry.grams))
                    .font(SBFont.caption()).foregroundColor(.sbTextSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(entry.nutrition.calories)) kcal")
                    .font(SBFont.body()).fontWeight(.semibold).foregroundColor(.sbTextPrimary)
                Text(String(format: "P%.0f  C%.0f  F%.0f",
                            entry.nutrition.protein, entry.nutrition.carbs, entry.nutrition.fat))
                    .font(SBFont.label(10)).foregroundColor(.sbTextSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { store.remove(entry) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - MealType Identifiable (for sheet)

extension MealType: Identifiable {
    public var id: String { rawValue }
}
