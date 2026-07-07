import SwiftUI
import MapKit
import CoreLocation

struct RunningView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var run = RunStore.shared
    @ObservedObject private var location = LocationService.shared

    @State private var activity: RunActivityType = .run
    @State private var showFinishConfirm = false
    @State private var didStartOnAppear = false
    @State private var finishedSession: RunSession?

    // AI route guidance
    @State private var plannedRoute: PlannedRoute?
    @State private var showPlanner = false
    @State private var announcedManeuvers: Set<UUID> = []
    @State private var announcedStageB = false
    @State private var announcedStageC = false

    var body: some View {
        ZStack(alignment: .bottom) {
            mapLayer
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer()
            }

            statsPanel
        }
        .onAppear { ensureAuthAndStartIfReady() }
        .onChange(of: location.authorizationStatus) { _ in ensureAuthAndStartIfReady() }
        .onReceive(location.locationPublisher) { loc in handleGuidance(loc) }
        .sheet(isPresented: $showPlanner) {
            RoutePlannerView { accepted in
                plannedRoute = accepted
            }
        }
        .alert("Finish run?", isPresented: $showFinishConfirm) {
            Button("Discard", role: .destructive) {
                run.discard()
                dismiss()
            }
            Button("Save") {
                if let session = run.finish(), session.route.count >= 2 {
                    finishedSession = session
                } else {
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Save this run to your history and Apple Health?")
        }
        .fullScreenCover(item: $finishedSession, onDismiss: { dismiss() }) { session in
            RunSummaryView(session: session)
        }
    }

    // MARK: - Map

    private var mapLayer: some View {
        RunMapView(routeCoordinates: run.activeSession?.route.map(\.coordinate) ?? [],
                   userLocation: location.lastLocation?.coordinate,
                   plannedRoute: plannedRoute)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button {
                if run.activeSession != nil { showFinishConfirm = true } else { dismiss() }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Circle())
            }
            Spacer()
            activityPicker
            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var activityPicker: some View {
        HStack(spacing: 0) {
            ForEach(RunActivityType.allCases, id: \.self) { type in
                Button {
                    guard run.activeSession == nil else { return }
                    activity = type
                    HapticManager.light()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: type.icon)
                            .font(.system(size: 12, weight: .semibold))
                        Text(LocalizedStringKey(type.rawValue))
                            .font(SBFont.label(11))
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(activity == type ? .white : .sbTextPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(activity == type ? Color.sbAccent : Color.clear)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(.thinMaterial)
        .cornerRadius(13)
        .opacity(run.activeSession == nil ? 1 : 0.55)
    }

    // MARK: - Stats panel

    private var statsPanel: some View {
        VStack(spacing: 16) {
            authBlocker

            if location.authorizationStatus == .authorizedWhenInUse
                || location.authorizationStatus == .authorizedAlways {
                if run.activeSession == nil { routeBar }
                statsRow
                controlsRow
            }
        }
        .padding(20)
        .padding(.bottom, 8)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // Route generator entry point (only before a run starts)
    @ViewBuilder
    private var routeBar: some View {
        if let planned = plannedRoute {
            HStack(spacing: 12) {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                    .foregroundColor(.sbAccent)
                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: String(format: "%.1f %@ · A → B → C", planned.distanceKm, PT("route.km")))
                        .font(SBFont.heading(14))
                        .foregroundColor(.sbTextPrimary)
                    Text(verbatim: PT("route.plannedLabel"))
                        .font(SBFont.label(10))
                        .foregroundColor(.sbTextSecondary)
                }
                Spacer()
                Button { plannedRoute = nil } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.sbTextSecondary)
                }
            }
            .padding(12)
            .background(Color.sbAccent.opacity(0.12))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sbAccent.opacity(0.35)))
        } else {
            Button { showPlanner = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text(verbatim: PT("route.generate"))
                        .fontWeight(.semibold)
                }
                .font(SBFont.body())
                .foregroundColor(.sbAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.sbAccent.opacity(0.12))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sbAccent.opacity(0.35)))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var authBlocker: some View {
        switch location.authorizationStatus {
        case .notDetermined:
            VStack(spacing: 10) {
                Text("Location access needed")
                    .font(SBFont.heading(15))
                    .foregroundColor(.sbTextPrimary)
                Text("PowerPump uses your location to trace your route and measure distance.")
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
                    .multilineTextAlignment(.center)
                SBPrimaryButton(title: "Allow Location") {
                    location.requestAuthorization()
                }
            }
        case .denied, .restricted:
            VStack(spacing: 8) {
                Text("Location is off")
                    .font(SBFont.heading(15))
                    .foregroundColor(.sbTextPrimary)
                Text("Enable location for PowerPump in iOS Settings to track your runs.")
                    .font(SBFont.caption())
                    .foregroundColor(.sbTextSecondary)
                    .multilineTextAlignment(.center)
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .font(SBFont.body())
                        .fontWeight(.semibold)
                        .foregroundColor(.sbAccent)
                }
            }
        default:
            EmptyView()
        }
    }

    private var statsRow: some View {
        HStack(alignment: .top, spacing: 12) {
            statCell(title: "Time", value: formattedTime, big: true)
            Divider().frame(height: 56)
            statCell(title: "Km", value: formattedDistance, big: true)
            Divider().frame(height: 56)
            statCell(title: "Pace", value: formattedPace, big: false)
            Divider().frame(height: 56)
            statCell(title: "kcal", value: "\(run.activeSession?.calories ?? 0)", big: false)
        }
        .frame(maxWidth: .infinity)
    }

    private func statCell(title: String, value: String, big: Bool) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(SBFont.display(big ? 28 : 22))
                .foregroundColor(.sbTextPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(LocalizedStringKey(title))
                .font(SBFont.label(10))
                .foregroundColor(.sbTextSecondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    private var controlsRow: some View {
        HStack(spacing: 16) {
            if run.activeSession == nil {
                Button {
                    HapticManager.medium()
                    startRun()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Start")
                            .fontWeight(.bold)
                    }
                    .font(SBFont.heading(16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.sbAccent)
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    HapticManager.light()
                    if run.isPaused { run.resume() } else { run.pause() }
                } label: {
                    Image(systemName: run.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.sbTextPrimary)
                        .frame(width: 56, height: 56)
                        .background(Color.sbSurfaceRaised)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button {
                    HapticManager.medium()
                    showFinishConfirm = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.fill")
                        Text("Finish")
                            .fontWeight(.bold)
                    }
                    .font(SBFont.heading(16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.sbRed)
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Run lifecycle

    private func startRun() {
        announcedManeuvers.removeAll()
        announcedStageB = false
        announcedStageC = false
        run.start(activity: activity)
        if plannedRoute != nil {
            RunningCoach.shared.announce(PT("voice.route.start"))
            RunningCoach.shared.cueIntervalChange()
        }
    }

    // MARK: - Voice guidance

    private func handleGuidance(_ loc: CLLocation) {
        guard let planned = plannedRoute,
              run.activeSession != nil, !run.isPaused else { return }
        let coach = RunningCoach.shared

        // Turn-by-turn: announce the closest un-announced maneuver within 45 m.
        var nearest: (RouteManeuver, Double)?
        for m in planned.maneuvers where !announcedManeuvers.contains(m.id) {
            let mLoc = CLLocation(latitude: m.coordinate.latitude, longitude: m.coordinate.longitude)
            let d = loc.distance(from: mLoc)
            if d < 45, nearest == nil || d < nearest!.1 { nearest = (m, d) }
        }
        if let (m, _) = nearest {
            announcedManeuvers.insert(m.id)
            coach.announce(m.instruction)
            coach.cueCountdown()
        }

        // Stage announcements by distance covered.
        let covered = run.activeSession?.distanceMeters ?? 0
        if !announcedStageB, covered >= planned.totalDistance * 0.5 {
            announcedStageB = true
            coach.announce(PT("voice.route.stageB"))
            coach.cueIntervalChange()
        }
        if !announcedStageC, covered >= planned.totalDistance * 0.85 {
            announcedStageC = true
            coach.announce(PT("voice.route.stageC"))
            coach.cueIntervalChange()
        }
    }

    // MARK: - Helpers

    private func ensureAuthAndStartIfReady() {
        if !didStartOnAppear,
           location.authorizationStatus == .authorizedWhenInUse
            || location.authorizationStatus == .authorizedAlways {
            location.startTracking()
            didStartOnAppear = true
        }
    }

    private var session: RunSession? { run.activeSession }

    private var formattedTime: String {
        let total = Int(session?.movingSeconds ?? 0)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }

    private var formattedDistance: String {
        String(format: "%.2f", (session?.distanceKm ?? 0))
    }

    private var formattedPace: String {
        guard let pace = session?.paceSecondsPerKm, pace > 0 else { return "--'--\"" }
        let m = Int(pace) / 60
        let s = Int(pace) % 60
        return String(format: "%d'%02d\"", m, s)
    }
}

// MARK: - MKMapView wrapper (iOS 16 compatible)

private struct RunMapView: UIViewRepresentable {
    let routeCoordinates: [CLLocationCoordinate2D]
    let userLocation: CLLocationCoordinate2D?
    var plannedRoute: PlannedRoute? = nil

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.showsUserLocation = true
        map.userTrackingMode = .follow
        map.isPitchEnabled = false
        map.isRotateEnabled = true
        map.delegate = context.coordinator
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        map.removeOverlays(map.overlays)
        map.removeAnnotations(map.annotations)

        if let planned = plannedRoute, planned.coordinates.count >= 2 {
            // Guided run: show the route to follow + the A/B/C stage pins.
            let line = MKPolyline(coordinates: planned.coordinates, count: planned.coordinates.count)
            map.addOverlay(line)
            map.addAnnotations([
                StageAnnotation(coordinate: planned.startCoord, stage: "A"),
                StageAnnotation(coordinate: planned.midCoord,   stage: "B"),
                StageAnnotation(coordinate: planned.endCoord,   stage: "C"),
            ])
            // Fit to the route only once, before the run starts moving the camera.
            if !context.coordinator.didFitPlanned {
                context.coordinator.didFitPlanned = true
                map.setVisibleMapRect(line.boundingMapRect,
                                      edgePadding: UIEdgeInsets(top: 70, left: 40, bottom: 260, right: 40),
                                      animated: false)
            }
        } else if routeCoordinates.count >= 2 {
            // Free run: trace where the user has actually been.
            let polyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
            map.addOverlay(polyline)
        }

        if let loc = userLocation, map.userTrackingMode == .none {
            map.setCenter(loc, animated: true)
        }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var didFitPlanned = false

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let line = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
            let renderer = MKPolylineRenderer(polyline: line)
            renderer.strokeColor = UIColor(named: "AccentColor") ?? .systemBlue
            renderer.lineWidth = 5
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
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
