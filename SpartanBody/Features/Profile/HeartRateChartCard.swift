import SwiftUI
import Charts

struct HeartRateChartCard: View {
    let samples: [HeartRateSample]

    private var minBPM: Double { samples.map(\.bpm).min() ?? 0 }
    private var maxBPM: Double { samples.map(\.bpm).max() ?? 0 }

    private var headerValue: String {
        guard !samples.isEmpty else { return "-- " }
        return "\(Int(minBPM))–\(Int(maxBPM)) "
    }

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
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(headerValue)
                                .font(SBFont.heading(22))
                                .foregroundColor(.sbTextPrimary)
                                .monospacedDigit()
                            Text("lpm")
                                .font(SBFont.body())
                                .foregroundColor(.sbTextSecondary)
                        }
                        Text(weekRange)
                            .font(SBFont.label(11))
                            .foregroundColor(.sbTextSecondary)
                    }
                    Spacer()
                }

                chart
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(samples) { sample in
                BarMark(
                    x: .value("Day", sample.date, unit: .day),
                    yStart: .value("Min", max(sample.bpm - 8, 0)),
                    yEnd:   .value("Max", sample.bpm + 8),
                    width: .fixed(6)
                )
                .foregroundStyle(Color.sbRed)
                .clipShape(Capsule())
            }
        }
        .frame(height: 180)
        .chartYScale(domain: 0...200)
        .chartXScale(domain: weekDomain)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { val in
                AxisValueLabel(format: .dateTime.weekday(.narrow),
                               centered: true)
                    .font(SBFont.label(11))
                    .foregroundStyle(Color.sbTextSecondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: [0, 100, 200]) { val in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                    .foregroundStyle(Color.sbTextSecondary.opacity(0.18))
                AxisValueLabel {
                    if let v = val.as(Int.self) {
                        Text("\(v)")
                            .font(SBFont.label(10))
                            .foregroundColor(.sbTextSecondary.opacity(0.7))
                    }
                }
            }
        }
    }

    private var weekDomain: ClosedRange<Date> {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let start = cal.date(byAdding: .day, value: -6, to: today) ?? today
        let end   = cal.date(byAdding: .day, value: 1,  to: today) ?? today
        return start...end
    }
}
