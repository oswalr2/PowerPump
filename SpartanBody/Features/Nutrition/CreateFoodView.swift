import SwiftUI

// Capture label data once for products no database knows about.
struct CreateFoodView: View {
    let onCreated: (FoodItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name     = ""
    @State private var calories = ""
    @State private var protein  = ""
    @State private var carbs    = ""
    @State private var fat      = ""

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && kcalValue != nil
            && macroValue(protein) != nil
            && macroValue(carbs) != nil
            && macroValue(fat) != nil
    }

    /// kcal per 100 g; nothing edible exceeds ~900 (pure fat).
    private var kcalValue: Double? {
        guard let v = calories.localizedDouble, (0...900).contains(v) else { return nil }
        return v
    }

    /// Grams per 100 g. Left empty means 0; anything unparseable is invalid.
    private func macroValue(_ text: String) -> Double? {
        if text.trimmingCharacters(in: .whitespaces).isEmpty { return 0 }
        guard let v = text.localizedDouble, (0...100).contains(v) else { return nil }
        return v
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sbBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        Text("Enter the values from the nutrition label, per 100g.")
                            .font(SBFont.caption())
                            .foregroundColor(.sbTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        field("Name", text: $name, placeholder: NSLocalizedString("Protein bar XYZ", comment: ""), keyboard: .default)
                        field("Calories (kcal)", text: $calories, placeholder: "350")
                        field("Protein (g)", text: $protein, placeholder: "20")
                        field("Carbs (g)", text: $carbs, placeholder: "40")
                        field("Fat (g)", text: $fat, placeholder: "12")

                        SBPrimaryButton(title: "Save") {
                            let item = CustomFoodStore.shared.add(
                                name: name.trimmingCharacters(in: .whitespaces),
                                caloriesPer100g: kcalValue ?? 0,
                                protein: macroValue(protein) ?? 0,
                                carbs:   macroValue(carbs) ?? 0,
                                fat:     macroValue(fat) ?? 0
                            )
                            HapticManager.success()
                            dismiss()
                            onCreated(item)
                        }
                        .opacity(isValid ? 1 : 0.45)
                        .disabled(!isValid)
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(Text("New Food"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.sbAccent)
                }
            }
        }
    }

    private func field(_ label: String, text: Binding<String>,
                       placeholder: String, keyboard: UIKeyboardType = .decimalPad) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(label))
                .font(SBFont.caption())
                .foregroundColor(.sbTextSecondary)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .font(SBFont.body())
                .foregroundColor(.sbTextPrimary)
                .padding(12)
                .background(Color.sbSurface)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.sbBorder))
        }
    }
}
