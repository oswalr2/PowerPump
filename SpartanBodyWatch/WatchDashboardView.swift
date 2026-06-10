import SwiftUI

struct WatchDashboardView: View {
    @ObservedObject private var store = WatchConnectivityManager.shared

    private var calorieProgress: Double {
        store.calorieTarget > 0
            ? min(Double(store.calories) / Double(store.calorieTarget), 1.0)
            : 0
    }
    private var proteinProgress: Double {
        store.proteinTarget > 0
            ? min(store.protein / Double(store.proteinTarget), 1.0)
            : 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {

                // Calorie ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 8)
                        .frame(width: 90, height: 90)
                    Circle()
                        .trim(from: 0, to: calorieProgress)
                        .stroke(
                            calorieProgress >= 1 ? Color.red : Color.blue,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 90, height: 90)
                        .animation(.easeOut(duration: 0.6), value: calorieProgress)

                    VStack(spacing: 1) {
                        Text("\(store.calories)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("/ \(store.calorieTarget)")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }

                // Steps + Streak row
                HStack(spacing: 14) {
                    statBadge(
                        icon: "figure.walk",
                        value: formatSteps(store.steps),
                        color: .blue
                    )
                    statBadge(
                        icon: "flame.fill",
                        value: "\(store.streak)",
                        color: .orange
                    )
                }

                // Protein bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Protein")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(Int(store.protein))g / \(store.proteinTarget)g")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 5)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.green)
                                .frame(width: geo.size.width * proteinProgress, height: 5)
                                .animation(.easeOut(duration: 0.6), value: proteinProgress)
                        }
                    }
                    .frame(height: 5)
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
        }
        .navigationTitle("Today")
    }

    private func statBadge(icon: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
        .cornerRadius(10)
    }

    private func formatSteps(_ n: Int) -> String {
        n >= 1000 ? String(format: "%.1fk", Double(n) / 1000) : "\(n)"
    }
}
