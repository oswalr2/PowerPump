import SwiftUI
import Charts

struct HeartRateChartCard: View {
    let samples: [HeartRateSample]

    private var avgBPM: Double {
        guard !samples.isEmpty else { return 0 }
        return samples.reduce(0) { $0 + $1.bpm } / Double(samples.count)
    }

    private var minBPM: Double { samples.map(\.bpm).min() ?? 0 }
    private var maxBPM: Double { samples.map(\.bpm).max() ?? 0 }

    private var weekRange: String {
        let cal = Calendar.current
        let today = Date()
        guard let start = cal.date(byAdding: .day, value: -6, to: today) else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM"
        fmt.locale = Locale(identifier: LanguageManager.shared.selectedCode)
        return "\(fmt.string(from: start)) – \(fmt.string(from: today))"
    }

    var body: some View {
        SBCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .center) {
                    Label {
                        Text("Weekly Heart Rate")
                            .font(SBFont.heading())
                            .foregroundColor(.sbTextPrimary)
                    } icon: {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.sbRed)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        if samples.isEmpty {
                            Text("-- lpm")
                                .font(SBFont.heading(18))
                                .foregroundColor(.sbTextSecondary)
                                .monospacedDigit()
                        } else {
                            Text("\(Int(avgBPM)) lpm")
                                .font(SBFont.heading(18))
                                .foregroundColor(.sbRed)
                                .monospacedDigit()
                        }
                        Text(weekRange)
                            .font(SBFont.label(10))
                            .foregroundColor(.sbTextSecondary)
                    }
                }

                if samples.isEmpty {
                    emptyChart
                } else {
                    filledChart
                    minMaxRow
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyChart: some View {
        VStack(spacing: 8) {
            Chart {
                ForEach(placeholderDays, id: \.self) { day in
                    BarMark(
                        x: .value("Day", day),
                        y: .value("BPM", 0)
                    )
                }
            }
            .frame(height: 110)
            .chartXAxis {
                AxisMarks(values: placeholderDays) { val in
                    AxisValueLabel {
                        if let s = val.as(String.self) {
                            Text(s)
                                .font(SBFont.label(10))
                                .foregroundColor(.sbTextSecondary)
                        }
                    }
                }
            }
            .chartYAxis(.hidden)
            .overlay(
                Text("No heart rate data this week")
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary.opacity(0.6))
            )
        }
    }

    // MARK: - Filled chart

    private var filledChart: some View {
        Chart(samples) { sample in
            BarMark(
                x: .value("Day", dayLabel(for: sample.date)),
                y: .value("BPM", sample.bpm)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.sbRed.opacity(0.9), Color.sbRed.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(6)

            RuleMark(y: .value("Avg", avgBPM))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .foregroundStyle(Color.sbRed.opacity(0.45))
        }
        .frame(height: 120)
        .chartXAxis {
            AxisMarks { val in
                AxisValueLabel {
                    if let s = val.as(String.self) {
                        Text(s)
                            .font(SBFont.label(10))
                            .foregroundColor(.sbTextSecondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { val in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                    .foregroundStyle(Color.sbTextSecondary.opacity(0.2))
                AxisValueLabel {
                    if let v = val.as(Double.self) {
                        Text("\(Int(v))")
                            .font(SBFont.label(9))
                            .foregroundColor(.sbTextSecondary.opacity(0.6))
                    }
                }
            }
        }
    }

    private var minMaxRow: some View {
        HStack {
            Label {
                Text("Min: \(Int(minBPM)) lpm")
                    .font(SBFont.label(11))
                    .foregroundColor(.sbTextSecondary)
            } icon: {
                Image(systemName: "arrow.down.heart")
                    .font(.system(size: 10))
                    .foregroundColor(.sbAccent)
            }
            Spacer()
            Label {
                Text("Avg: \(Int(avgBPM)) lpm")
                    .font(SBFont.label(11))
                    .foregroundColor(.sbTextSecondary)
            } icon: {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 10))
                    .foregroundColor(.sbRed)
            }
            Spacer()
            Label {
                Text("Max: \(Int(maxBPM)) lpm")
                    .font(SBFont.label(11))
                    .foregroundColor(.sbTextSecondary)
            } icon: {
                Image(systemName: "arrow.up.heart")
                    .font(.system(size: 10))
                    .foregroundColor(.sbRed)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private func dayLabel(for date: Date) -> String {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: date)
        let labels = ["D", "L", "M", "X", "J", "V", "S"]
        return labels[weekday % 7]
    }

    private var placeholderDays: [String] { ["L", "M", "X", "J", "V", "S", "D"] }
}
