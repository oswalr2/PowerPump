import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct CalorieEntry: TimelineEntry {
    let date: Date
    let calories: Int
    let calorieTarget: Int
    let streak: Int

    var progress: Double {
        calorieTarget > 0 ? min(Double(calories) / Double(calorieTarget), 1.0) : 0
    }
}

// MARK: - Provider

struct SpartanBodyProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalorieEntry {
        CalorieEntry(date: .now, calories: 1400, calorieTarget: 2000, streak: 5)
    }

    func getSnapshot(in context: Context, completion: @escaping (CalorieEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalorieEntry>) -> Void) {
        let entry = currentEntry()
        let next  = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func currentEntry() -> CalorieEntry {
        let defaults = UserDefaults(suiteName: "group.com.oswaldo.powerpump")
        let calories  = defaults?.integer(forKey: "watch_calories")      ?? 0
        let target    = defaults?.integer(forKey: "watch_calorieTarget") ?? 2000
        let streak    = defaults?.integer(forKey: "watch_streak")        ?? 0
        return CalorieEntry(date: .now, calories: calories, calorieTarget: target, streak: streak)
    }
}

// MARK: - Widget

@main
struct SpartanBodyComplicationWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SpartanBodyComplication", provider: SpartanBodyProvider()) { entry in
            SpartanBodyComplicationView(entry: entry)
        }
        .configurationDisplayName("PowerPump")
        .description("Calorie progress ring")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryCorner])
    }
}

// MARK: - Views

struct SpartanBodyComplicationView: View {
    @Environment(\.widgetFamily) var family
    let entry: CalorieEntry

    var body: some View {
        switch family {
        case .accessoryCircular:   circularView
        case .accessoryRectangular: rectangularView
        case .accessoryCorner:     cornerView
        default:                   circularView
        }
    }

    // Circular — calorie progress ring
    private var circularView: some View {
        Gauge(value: entry.progress) {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
        } currentValueLabel: {
            Text("\(Int(entry.progress * 100))%")
                .font(.system(size: 9, weight: .bold))
        }
        .gaugeStyle(.accessoryCircular)
        .tint(entry.progress >= 1 ? .red : .blue)
    }

    // Rectangular — calories + streak
    private var rectangularView: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Label("\(entry.calories) kcal", systemImage: "flame.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                ProgressView(value: entry.progress)
                    .tint(entry.progress >= 1 ? .red : .blue)
                    .frame(height: 4)
                Text("/ \(entry.calorieTarget) target")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            Spacer()
            VStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
                Text("\(entry.streak)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    // Corner — simple calorie count
    private var cornerView: some View {
        Label {
            Text("\(entry.calories)")
                .font(.system(size: 12, weight: .bold))
        } icon: {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
        }
        .widgetLabel("\(Int(entry.progress * 100))%")
    }
}
