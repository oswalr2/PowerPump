import SwiftUI
import MapKit
import CoreLocation

/// Shown after a run or program session finishes. Big map with the full
/// route, plus the headline stats below. No overlay so the path is
/// clearly visible.
struct RunSummaryView: View {
    @Environment(\.dismiss) private var dismiss

    let session: RunSession
    /// Optional context for program sessions ("Caminar para Adelgazar · Week 1 Day 2").
    let programContext: String?

    init(session: RunSession, programContext: String? = nil) {
        self.session = session
        self.programContext = programContext
    }

    var body: some View {
        ZStack {
            Color.sbBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                mapSection
                statsSection
                doneButton
            }
        }
    }

    // MARK: - Map

    private var mapSection: some View {
        ZStack(alignment: .topLeading) {
            RouteMap(coordinates: session.route.map(\.coordinate))
                .frame(maxWidth: .infinity)
                .frame(height: 360)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .shadow(color: .black.opacity(0.18), radius: 20, y: 8)

            VStack(alignment: .leading, spacing: 6) {
                if let programContext {
                    Text(programContext)
                        .font(SBFont.label(11))
                        .foregroundColor(.sbAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 22)
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(spacing: 18) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.sbGreen)
                Text(LocalizedStringKey("Workout complete"))
                    .font(SBFont.heading(18))
                    .foregroundColor(.sbTextPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)

            HStack(spacing: 0) {
                statCell(value: formattedDistance, unit: "km", label: "Distance")
                Divider().frame(height: 52)
                statCell(value: formattedTime, unit: "", label: "Time")
            }
            .padding(.horizontal, 24)

            HStack(spacing: 0) {
                statCell(value: formattedPace, unit: "min/km", label: "Avg Pace")
                Divider().frame(height: 52)
                statCell(value: "\(session.calories)", unit: "kcal", label: "Burned")
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 22)
    }

    private func statCell(value: String, unit: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(SBFont.display(28))
                    .foregroundColor(.sbTextPrimary)
                    .monospacedDigit()
                if !unit.isEmpty {
                    Text(unit)
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)
                }
            }
            Text(LocalizedStringKey(label))
                .font(SBFont.label(10))
                .foregroundColor(.sbTextSecondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Done button

    private var doneButton: some View {
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
                .background(
                    LinearGradient(colors: [.sbAccent, .sbAccent.opacity(0.7)],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.bottom, 22)
        .padding(.top, 24)
    }

    // MARK: - Formatters

    private var formattedDistance: String {
        String(format: "%.2f", session.distanceKm)
    }

    private var formattedTime: String {
        let t = Int(session.movingSeconds)
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }

    private var formattedPace: String {
        guard session.distanceKm > 0 else { return "--'--\"" }
        let secPerKm = Int(session.paceSecondsPerKm)
        let m = secPerKm / 60
        let s = secPerKm % 60
        return String(format: "%d'%02d\"", m, s)
    }
}

// MARK: - Route map (fits camera to the route)

private struct RouteMap: UIViewRepresentable {
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

        // Start + end pins so the user can see where they began and ended.
        let start = MKPointAnnotation()
        start.coordinate = coordinates.first!
        start.title = "Start"
        let end = MKPointAnnotation()
        end.coordinate = coordinates.last!
        end.title = "Finish"
        map.addAnnotations([start, end])

        // Fit the camera to the whole route with a comfortable padding.
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
