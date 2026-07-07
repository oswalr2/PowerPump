import SwiftUI
import MapKit
import CoreLocation

/// Lets the runner pick a distance and have PowerPump generate a loop route
/// from their current position, preview it on a map (with A/B/C stage pins),
/// regenerate for a different one, and hand the chosen route back to the
/// running view for guided tracking.
struct RoutePlannerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var location  = LocationService.shared
    @ObservedObject private var generator = RouteGenerator.shared

    /// Called with the accepted route when the user taps "Run this route".
    let onAccept: (PlannedRoute) -> Void

    @State private var selectedKm: Double = 5
    @State private var customKm: String = ""
    @State private var route: PlannedRoute?
    @State private var seed = Int.random(in: 0..<1000)
    @State private var errorText: String?

    private let presets: [Double] = [3, 5, 10, 15]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sbBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    if let route {
                        RoutePreviewMap(route: route)
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .overlay(alignment: .bottomLeading) {
                                distancePill(route.distanceKm)
                                    .padding(24)
                            }
                    } else {
                        placeholderMap
                    }

                    ScrollView {
                        VStack(spacing: 20) {
                            distancePicker
                            if let errorText {
                                Text(verbatim: errorText)
                                    .font(SBFont.caption())
                                    .foregroundColor(.sbRed)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                            actionButtons
                        }
                        .padding(.top, 22)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle(Text(verbatim: PT("route.title")))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.sbTextSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Placeholder (before first generation)

    private var placeholderMap: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.sbSurface)
            VStack(spacing: 12) {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.sbAccent.opacity(0.7))
                Text(verbatim: PT("route.subtitle"))
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
        }
        .frame(height: 300)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Distance picker

    private var distancePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: PT("route.pickDistance"))
                .font(SBFont.heading(15))
                .foregroundColor(.sbTextPrimary)
                .padding(.horizontal, 20)

            HStack(spacing: 10) {
                ForEach(presets, id: \.self) { km in
                    chip(label: "\(Int(km)) \(PT("route.km"))", selected: selectedKm == km && customKm.isEmpty) {
                        selectedKm = km
                        customKm = ""
                    }
                }
            }
            .padding(.horizontal, 20)

            HStack(spacing: 10) {
                Text(verbatim: PT("route.custom"))
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
                TextField("", text: $customKm)
                    .keyboardType(.decimalPad)
                    .font(SBFont.body())
                    .foregroundColor(.sbTextPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(width: 90)
                    .background(Color.sbSurface)
                    .cornerRadius(10)
                Text(verbatim: PT("route.km"))
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }

    private func chip(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(verbatim: label)
                .font(SBFont.label(13))
                .fontWeight(.semibold)
                .foregroundColor(selected ? .white : .sbTextPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(selected ? Color.sbAccent : Color.sbSurface)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private func distancePill(_ km: Double) -> some View {
        Text(verbatim: String(format: "%.1f %@", km, PT("route.km")))
            .font(SBFont.heading(15))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }

    // MARK: - Actions

    private var targetMeters: Double {
        if let c = Double(customKm.replacingOccurrences(of: ",", with: ".")), c >= 1, c <= 42 {
            return c * 1000
        }
        return selectedKm * 1000
    }

    @ViewBuilder
    private var actionButtons: some View {
        if generator.isGenerating {
            HStack(spacing: 10) {
                ProgressView().tint(.white)
                Text(verbatim: PT("route.generating"))
                    .font(SBFont.heading(16)).foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.sbAccent.opacity(0.7))
            .cornerRadius(16)
            .padding(.horizontal, 20)
        } else if route == nil {
            SBPrimaryButton(title: PT("route.generate")) { generate() }
                .padding(.horizontal, 20)
        } else {
            VStack(spacing: 12) {
                Button {
                    if let r = route { onAccept(r); dismiss() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.run")
                        Text(verbatim: PT("route.runThis")).fontWeight(.bold)
                    }
                    .font(SBFont.heading(17))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.sbAccent)
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)

                Button { generate() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text(verbatim: PT("route.regenerate")).fontWeight(.semibold)
                    }
                    .font(SBFont.body())
                    .foregroundColor(.sbAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.sbSurface)
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
        }
    }

    private func generate() {
        errorText = nil
        guard let origin = location.lastLocation?.coordinate else {
            errorText = PT("route.failed")
            return
        }
        seed = Int.random(in: 0..<1000)
        let target = targetMeters
        Task {
            do {
                let result = try await generator.generateLoop(from: origin,
                                                              targetMeters: target,
                                                              seed: seed)
                await MainActor.run { self.route = result }
            } catch {
                await MainActor.run {
                    self.route = nil
                    self.errorText = PT("route.failed")
                }
            }
        }
    }
}

// MARK: - Static preview map (fits the whole route, shows A/B/C pins)

private struct RoutePreviewMap: UIViewRepresentable {
    let route: PlannedRoute

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.isPitchEnabled = false
        map.showsUserLocation = true
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        map.removeOverlays(map.overlays)
        map.removeAnnotations(map.annotations)

        guard route.coordinates.count >= 2 else { return }
        let line = MKPolyline(coordinates: route.coordinates, count: route.coordinates.count)
        map.addOverlay(line)

        let a = StageAnnotation(coordinate: route.startCoord, stage: "A")
        let b = StageAnnotation(coordinate: route.midCoord,   stage: "B")
        let c = StageAnnotation(coordinate: route.endCoord,   stage: "C")
        map.addAnnotations([a, b, c])

        map.setVisibleMapRect(line.boundingMapRect,
                              edgePadding: UIEdgeInsets(top: 50, left: 40, bottom: 50, right: 40),
                              animated: false)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ map: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let line = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
            let r = MKPolylineRenderer(polyline: line)
            r.strokeColor = UIColor(named: "AccentColor") ?? .systemBlue
            r.lineWidth = 5
            r.lineCap = .round
            r.lineJoin = .round
            return r
        }

        func mapView(_ map: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let stage = annotation as? StageAnnotation else { return nil }
            let id = "stage"
            let view = map.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.annotation = annotation
            view.glyphText = stage.stage
            switch stage.stage {
            case "A": view.markerTintColor = .systemGreen
            case "C": view.markerTintColor = .systemRed
            default:  view.markerTintColor = UIColor(named: "AccentColor") ?? .systemBlue
            }
            view.displayPriority = .required
            return view
        }
    }
}

/// Annotation for the A / B / C stage pins.
final class StageAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let stage: String
    init(coordinate: CLLocationCoordinate2D, stage: String) {
        self.coordinate = coordinate
        self.stage = stage
    }
}
