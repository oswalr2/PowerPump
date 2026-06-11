import SwiftUI

struct FoodSearchView: View {
    let meal: MealType
    @ObservedObject private var store = FoodLogStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var query      = ""
    @State private var selected: FoodItem?
    @State private var grams: Double = 100
    @State private var gramsText  = "100"
    @State private var category: FoodCategory? = nil

    private var results: [FoodItem] {
        var list = FoodDatabase.all
        if let cat = category { list = list.filter { $0.category == cat } }
        if !query.isEmpty { list = list.filter { $0.name.localizedCaseInsensitiveContains(query) } }
        return list
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sbBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                    categoryFilter
                    Divider().background(Color.sbBorder)

                    if let item = selected {
                        portionView(item: item)
                    } else {
                        foodList
                    }
                }
            }
            .navigationTitle("Add to \(NSLocalizedString(meal.rawValue, comment: ""))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.sbAccent)
                }
                if selected != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { confirmAdd() }
                            .fontWeight(.bold)
                            .foregroundColor(.sbAccent)
                    }
                }
            }
        }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundColor(.sbTextSecondary)
            TextField("Search food…", text: $query)
                .font(SBFont.body())
                .foregroundColor(.sbTextPrimary)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.sbTextSecondary)
                }
            }
        }
        .padding(12)
        .background(Color.sbSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.sbBorder))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Category filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(nil, label: "All")
                ForEach(FoodCategory.allCases, id: \.self) { cat in
                    categoryChip(cat, label: cat.rawValue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }

    private func categoryChip(_ cat: FoodCategory?, label: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { category = cat }
        } label: {
            Text(LocalizedStringKey(label))
                .font(SBFont.caption())
                .foregroundColor(category == cat ? .white : .sbTextSecondary)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(category == cat ? Color.sbAccent : Color.sbSurface)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(category == cat ? Color.sbAccent : Color.sbBorder))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Food list

    private var foodList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 8) {
                ForEach(results) { item in
                    Button { selected = item } label: {
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.name)
                                    .font(SBFont.body())
                                    .foregroundColor(.sbTextPrimary)
                                Text(String(format: "%.0f kcal · P%.0fg C%.0fg F%.0fg (per 100g)",
                                            item.per100g.calories, item.per100g.protein,
                                            item.per100g.carbs, item.per100g.fat))
                                    .font(SBFont.label(10))
                                    .foregroundColor(.sbTextSecondary)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.sbAccent)
                        }
                        .padding(14)
                        .background(Color.sbSurface)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.sbBorder))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Portion view

    private func portionView(item: FoodItem) -> some View {
        let n = item.nutrition(grams: grams)

        return ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Back button
                Button { selected = nil } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back to search")
                    }
                    .font(SBFont.caption())
                    .foregroundColor(.sbAccent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                // Food name
                Text(item.name)
                    .font(SBFont.heading(20))
                    .foregroundColor(.sbTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Portion input
                VStack(spacing: 10) {
                    Text("Portion (grams)")
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 12) {
                        Button { adjustGrams(-50) } label: { adjustBtn("-50") }
                        Button { adjustGrams(-10) } label: { adjustBtn("-10") }

                        TextField("100", text: $gramsText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(SBFont.heading(20))
                            .foregroundColor(.sbTextPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.sbSurface)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.sbBorder))
                            .onChange(of: gramsText) { val in
                                if let g = Double(val), g > 0 { grams = g }
                            }

                        Button { adjustGrams(10)  } label: { adjustBtn("+10") }
                        Button { adjustGrams(50)  } label: { adjustBtn("+50") }
                    }

                    // Quick portions
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([50, 100, 150, 200, 250, 300], id: \.self) { g in
                                Button { setGrams(Double(g)) } label: {
                                    Text("\(g)g")
                                        .font(SBFont.caption())
                                        .foregroundColor(Int(grams) == g ? .white : .sbTextSecondary)
                                        .padding(.horizontal, 14).padding(.vertical, 7)
                                        .background(Int(grams) == g ? Color.sbAccent : Color.sbSurface)
                                        .cornerRadius(20)
                                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Int(grams) == g ? Color.sbAccent : Color.sbBorder))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }

                // Nutrition preview
                VStack(spacing: 12) {
                    Text("Nutrition for \(Int(grams))g")
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 0) {
                        nutritionStat("Calories", "\(Int(n.calories))", "kcal")
                        Divider().frame(height: 40)
                        nutritionStat("Protein",  String(format: "%.1f", n.protein),  "g")
                        Divider().frame(height: 40)
                        nutritionStat("Carbs",    String(format: "%.1f", n.carbs),    "g")
                        Divider().frame(height: 40)
                        nutritionStat("Fat",      String(format: "%.1f", n.fat),      "g")
                    }
                    .padding(16)
                    .background(Color.sbSurface)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbBorder))
                }

                // Add button
                Button { confirmAdd() } label: {
                    Text("Add to \(NSLocalizedString(meal.rawValue, comment: ""))")
                        .font(SBFont.body())
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.sbAccent)
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
    }

    // MARK: - Helpers

    private func adjustGrams(_ delta: Double) {
        grams = max(1, grams + delta)
        gramsText = String(Int(grams))
    }

    private func setGrams(_ value: Double) {
        grams = value
        gramsText = String(Int(value))
    }

    private func adjustBtn(_ label: String) -> some View {
        Text(label)
            .font(SBFont.label())
            .foregroundColor(.sbTextPrimary)
            .frame(width: 44)
            .padding(.vertical, 10)
            .background(Color.sbSurfaceRaised)
            .cornerRadius(8)
    }

    private func nutritionStat(_ label: String, _ value: String, _ unit: String) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(SBFont.heading(18))
                    .foregroundColor(.sbTextPrimary)
                Text(unit)
                    .font(SBFont.label())
                    .foregroundColor(.sbTextSecondary)
            }
            Text(label)
                .font(SBFont.label(10))
                .foregroundColor(.sbTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func confirmAdd() {
        guard let item = selected else { return }
        HapticManager.success()
        store.add(item, grams: grams, meal: meal)
        dismiss()
    }
}
