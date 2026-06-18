import SwiftUI

struct LogWeightSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var profile  = UserProfile.shared
    @ObservedObject private var progress = ProgressStore.shared

    @State private var weightText: String
    @FocusState private var focused: Bool

    init() {
        _weightText = State(initialValue: String(format: "%.1f", UserProfile.shared.weightKg))
    }

    private var parsedWeight: Double? {
        let cleaned = weightText.replacingOccurrences(of: ",", with: ".")
        guard let v = Double(cleaned), v > 20, v < 400 else { return nil }
        return v
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.sbBackground.ignoresSafeArea()
                VStack(spacing: 24) {
                    header
                    weightField
                    if let last = progress.weightEntries.dropLast().last {
                        recentEntry(last)
                    }
                    Spacer()
                    saveButton
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.sbTextSecondary)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "scalemass.fill")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(.sbAccent)
            Text("Log Weight")
                .font(SBFont.heading(20))
                .foregroundColor(.sbTextPrimary)
            Text("Enter your current weight to keep your progress accurate")
                .font(SBFont.caption())
                .foregroundColor(.sbTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
    }

    private var weightField: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                TextField("", text: $weightText)
                    .keyboardType(.decimalPad)
                    .focused($focused)
                    .multilineTextAlignment(.center)
                    .font(SBFont.display(56))
                    .foregroundColor(.sbTextPrimary)
                    .frame(maxWidth: 200)
                Text("kg")
                    .font(SBFont.heading(20))
                    .foregroundColor(.sbTextSecondary)
            }
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(Color.sbSurface)
            .cornerRadius(20)

            if parsedWeight == nil && !weightText.isEmpty {
                Text("Enter a value between 20 and 400 kg")
                    .font(SBFont.label(11))
                    .foregroundColor(.sbRed)
            }
        }
        .onAppear { focused = true }
    }

    private func recentEntry(_ entry: WeightEntry) -> some View {
        HStack {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundColor(.sbTextSecondary)
            Text("Last entry")
                .font(SBFont.caption())
                .foregroundColor(.sbTextSecondary)
            Spacer()
            Text("\(String(format: "%.1f", entry.weightKg)) kg")
                .font(SBFont.body())
                .foregroundColor(.sbTextPrimary)
            Text(entry.date, format: .dateTime.day().month().locale(LanguageManager.shared.locale))
                .font(SBFont.label(11))
                .foregroundColor(.sbTextSecondary.opacity(0.6))
        }
        .padding(14)
        .background(Color.sbSurface)
        .cornerRadius(14)
    }

    private var saveButton: some View {
        SBPrimaryButton(title: "Save Weight") {
            guard let kg = parsedWeight else { return }
            profile.weightKg = kg
            progress.addEntry(weightKg: kg)
            HealthKitService.shared.saveBodyMass(kg: kg)
            dismiss()
        }
        .opacity(parsedWeight == nil ? 0.5 : 1.0)
        .disabled(parsedWeight == nil)
    }
}
