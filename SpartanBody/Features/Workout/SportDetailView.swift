import SwiftUI
import MapKit
import CoreLocation

/// Detail screen for a single sport: aggregate totals + history of past
/// sessions + "Start" button. Tap a past session row to see its details.
struct SportDetailView: View {
    let sport: SportActivity

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = SportSessionStore.shared
    @State private var presentedSession: Bool = false
    @State private var pastSession: SportSessionRecord?

    private var history: [SportSessionRecord] {
        store.sessions(for: sport.id)
    }

    var body: some View {
        ZStack {
            Color.sbBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    summaryCard
                    historySection
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            VStack { Spacer(); startButton }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(LocalizedStringKey(sport.nameKey))
                    .font(SBFont.heading(15))
                    .foregroundColor(.sbTextPrimary)
            }
        }
        .fullScreenCover(isPresented: $presentedSession) {
            SportSessionView(sport: sport)
        }
        .sheet(item: $pastSession) { record in
            PastSportSessionView(sport: sport, record: record)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.sbAccent.opacity(0.36),
                                 Color.sbAccent.opacity(0.08)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 96, height: 96)
                Image(systemName: sport.icon)
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundColor(.sbAccent)
            }
            VStack(spacing: 4) {
                Text(LocalizedStringKey(sport.nameKey))
                    .font(SBFont.display(28))
                    .foregroundColor(.sbTextPrimary)
                HStack(spacing: 6) {
                    Image(systemName: sport.category.icon)
                        .font(.system(size: 10))
                    Text(LocalizedStringKey(sport.category.rawValue))
                        .font(SBFont.label(11))
                }
                .foregroundColor(.sbTextSecondary)
                .textCase(.uppercase)
                if sport.usesGPS {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill").font(.system(size: 10))
                        Text(LocalizedStringKey("GPS"))
                            .font(SBFont.label(10))
                    }
                    .foregroundColor(.sbAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.sbAccent.opacity(0.15))
                    .cornerRadius(6)
                }
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Summary

    private var summaryCard: some View {
        SBCard {
            VStack(spacing: 12) {
                HStack {
                    Text(LocalizedStringKey("Your stats"))
                        .font(SBFont.heading())
                        .foregroundColor(.sbTextPrimary)
                    Spacer()
                    Text("\(store.totalSessions(for: sport.id))")
                        .font(SBFont.heading(18))
                        .foregroundColor(.sbAccent)
                        .monospacedDigit()
                    Text(LocalizedStringKey("sessions"))
                        .font(SBFont.label(11))
                        .foregroundColor(.sbTextSecondary)
                }

                HStack(spacing: 0) {
                    statCell(value: formattedTotalTime, label: "Total time")
                    Divider().frame(height: 40)
                    if sport.usesGPS {
                        statCell(value: formattedTotalDistance, label: "Distance")
                        Divider().frame(height: 40)
                    }
                    statCell(value: "\(store.totalCalories(for: sport.id))", label: "kcal")
                }
            }
        }
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(SBFont.heading(18))
                .foregroundColor(.sbTextPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(LocalizedStringKey(label))
                .font(SBFont.label(10))
                .foregroundColor(.sbTextSecondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(LocalizedStringKey("History"))
                    .font(SBFont.heading())
                    .foregroundColor(.sbTextPrimary)
                Spacer()
            }
            if history.isEmpty {
                emptyHistory
            } else {
                ForEach(history) { record in
                    Button {
                        HapticManager.light()
                        pastSession = record
                    } label: {
                        historyRow(record)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyHistory: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 26))
                .foregroundColor(.sbTextSecondary.opacity(0.5))
            Text(LocalizedStringKey("No sessions yet"))
                .font(SBFont.body())
                .foregroundColor(.sbTextSecondary)
            Text(LocalizedStringKey("Tap Start to log your first session."))
                .font(SBFont.label(11))
                .foregroundColor(.sbTextSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color.sbSurface)
        .cornerRadius(14)
    }

    private func historyRow(_ r: SportSessionRecord) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(formattedDate(r.startedAt))
                    .font(SBFont.body())
                    .fontWeight(.semibold)
                    .foregroundColor(.sbTextPrimary)
                HStack(spacing: 10) {
                    Label(formatted(seconds: Int(r.movingSeconds)), systemImage: "stopwatch")
                    if sport.usesGPS && r.distanceMeters > 0 {
                        Label(String(format: "%.2f km", r.distanceKm), systemImage: "location")
                    }
                    Label("\(r.calories) kcal", systemImage: "flame")
                }
                .font(SBFont.label(11))
                .foregroundColor(.sbTextSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.sbTextSecondary.opacity(0.5))
        }
        .padding(14)
        .background(Color.sbSurface)
        .cornerRadius(14)
    }

    // MARK: - Start button

    private var startButton: some View {
        Button {
            HapticManager.medium()
            presentedSession = true
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text(LocalizedStringKey("Start session"))
                    .fontWeight(.bold)
            }
            .font(SBFont.heading(18))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [.sbAccent, .sbAccent.opacity(0.7)],
                               startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(20)
            .shadow(color: Color.sbAccent.opacity(0.35), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Formatters

    private var formattedTotalTime: String {
        let secs = Int(store.totalSeconds(for: sport.id))
        let h = secs / 3600
        let m = (secs % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    private var formattedTotalDistance: String {
        let km = store.totalDistance(for: sport.id) / 1000
        return String(format: "%.1f km", km)
    }

    private func formatted(seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }

    private func formattedDate(_ d: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: LanguageManager.shared.selectedCode)
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: d)
    }
}

// MARK: - Past session view

struct PastSportSessionView: View {
    @Environment(\.dismiss) private var dismiss
    let sport: SportActivity
    let record: SportSessionRecord

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sbBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    if sport.usesGPS && record.route.count >= 2 {
                        PastRouteMap(coordinates: record.route.map(\.coordinate))
                            .frame(height: 340)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(LinearGradient(
                                    colors: [Color.sbAccent.opacity(0.18),
                                             Color.sbAccent.opacity(0.04)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                            VStack(spacing: 10) {
                                Image(systemName: sport.icon)
                                    .font(.system(size: 60))
                                    .foregroundColor(.sbAccent)
                                Text(LocalizedStringKey(sport.nameKey))
                                    .font(SBFont.heading(20))
                                    .foregroundColor(.sbTextPrimary)
                            }
                        }
                        .frame(height: 220)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }

                    statsBlock
                    Spacer()
                    Button {
                        HapticManager.light()
                        dismiss()
                    } label: {
                        Text(LocalizedStringKey("Done"))
                            .font(SBFont.heading(18))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.sbAccent)
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 22)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(formattedDate)
                        .font(SBFont.heading(14))
                        .foregroundColor(.sbTextPrimary)
                }
            }
        }
    }

    private var statsBlock: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.sbGreen)
                Text(LocalizedStringKey("Workout complete"))
                    .font(SBFont.heading(18))
                    .foregroundColor(.sbTextPrimary)
            }
            HStack(spacing: 0) {
                cell(value: formattedTime, label: "Time")
                if sport.usesGPS && record.distanceMeters > 0 {
                    Divider().frame(height: 52)
                    cell(value: String(format: "%.2f km", record.distanceKm), label: "Distance")
                }
                Divider().frame(height: 52)
                cell(value: "\(record.calories) kcal", label: "Burned")
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 22)
    }

    private func cell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(SBFont.display(22))
                .foregroundColor(.sbTextPrimary)
                .monospacedDigit()
            Text(LocalizedStringKey(label))
                .font(SBFont.label(10))
                .foregroundColor(.sbTextSecondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    private var formattedTime: String {
        let t = Int(record.movingSeconds)
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }

    private var formattedDate: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: LanguageManager.shared.selectedCode)
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: record.startedAt)
    }
}

// MARK: - Map for past route (fits camera to the whole route)

private struct PastRouteMap: UIViewRepresentable {
    let coordinates: [CLLocationCoordinate2D]

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.showsUserLocation = false
        map.isPitchEnabled = false
        map.isRotateEnabled = false
        map.delegate = context.coordinator
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        map.removeOverlays(map.overlays)
        map.removeAnnotations(map.annotations)
        guard coordinates.count >= 2 else { return }
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        map.addOverlay(polyline)
        let start = MKPointAnnotation()
        start.coordinate = coordinates.first!
        start.title = "Start"
        let end = MKPointAnnotation()
        end.coordinate = coordinates.last!
        end.title = "Finish"
        map.addAnnotations([start, end])
        map.setVisibleMapRect(
            polyline.boundingMapRect,
            edgePadding: UIEdgeInsets(top: 60, left: 40, bottom: 60, right: 40),
            animated: false
        )
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let line = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
            let renderer = MKPolylineRenderer(polyline: line)
            renderer.strokeColor = UIColor(named: "AccentColor") ?? .systemBlue
            renderer.lineWidth = 6
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            let id = "endpoint"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
                       ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.glyphImage = UIImage(systemName: annotation.title == "Start" ? "play.fill" : "flag.checkered")
            view.markerTintColor = annotation.title == "Start" ? .systemGreen : .systemRed
            view.displayPriority = .required
            return view
        }
    }
}
