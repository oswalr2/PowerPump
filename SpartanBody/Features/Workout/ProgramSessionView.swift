import SwiftUI
import CoreLocation
import MapKit

/// Player for a single day of a structured running program. Runs through
/// the intervals in order, announces transitions, tracks GPS, and marks the
/// day complete when finished.
struct ProgramSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var location = LocationService.shared
    @ObservedObject private var coach    = RunningCoach.shared
    @ObservedObject private var run      = RunStore.shared
    @ObservedObject private var progress = RunProgramStore.shared

    let program: RunningProgram
    let weekNumber: Int
    let day: ProgramDay
    /// Reopened at launch for a session the app was closed in the middle of.
    var resuming = false

    @State private var currentIndex = 0
    @State private var elapsedInCurrent: TimeInterval = 0
    @State private var totalElapsed: TimeInterval = 0
    @State private var isPaused = true
    @State private var didStart = false
    // Date-based anchors so the clock keeps advancing correctly when the
    // app is backgrounded or the screen is locked.
    @State private var sessionStartedAt: Date?
    @State private var pausedAccum: TimeInterval = 0
    @State private var pauseStartedAt: Date?
    @State private var didAnnounceHalfway = false
    @State private var didCountdown3 = false
    @State private var didCountdown2 = false
    @State private var didCountdown1 = false
    @State private var didFinish = false
    @State private var showFinishConfirm = false
    @State private var timer: Timer?
    @State private var finishedSession: RunSession?
    /// Seconds jumped over with "skip warm-up": they move the session along
    /// without counting as time trained.
    @State private var skipped: TimeInterval = 0
    /// Where the session is (time trained plus time skipped).
    @State private var position: TimeInterval = 0
    /// Skipped walking or running, which doesn't count towards finishing the day.
    @State private var skippedWork: TimeInterval = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            mapBackground
                .ignoresSafeArea()

            // Dark overlay so stats are readable on top of the map.
            LinearGradient(
                colors: [.black.opacity(0.55), .black.opacity(0.25), .clear,
                         .black.opacity(0.4), .black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer()
            }

            controlsPanel
        }
        .onAppear {
            ensureAuth()
            if resuming { resumeFromStore() }
        }
        .onDisappear { stopTimer() }
        .onChange(of: location.authorizationStatus) { _ in ensureAuth() }
        .onChange(of: scenePhase) { phase in
            // When the user comes back to the foreground, force a tick so
            // the UI immediately reflects the time that elapsed while we
            // were in the background.
            if phase == .active && didStart && !isPaused { tick(0) }
        }
        .alert(LocalizedStringKey("Finish session?"), isPresented: $showFinishConfirm) {
            Button(LocalizedStringKey("Discard"), role: .destructive) {
                cancelAndDismiss()
            }
            Button(LocalizedStringKey("Save")) {
                completeAndDismiss()
            }
            Button(LocalizedStringKey("Cancel"), role: .cancel) {}
        } message: {
            Text(verbatim: PT("Save your progress for this day?"))
        }
        .fullScreenCover(item: $finishedSession, onDismiss: { dismiss() }) { session in
            RunSummaryView(
                session: session,
                programContext: "\(PT(program.nameKey)) · " +
                    String(format: NSLocalizedString("Week %lld · Day %lld", comment: ""),
                           weekNumber, day.dayNumber)
            )
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button {
                if didStart && !didFinish { showFinishConfirm = true } else { dismiss() }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Circle())
            }
            Spacer()
            VStack(spacing: 2) {
                Text(verbatim: PT(program.nameKey))
                    .font(SBFont.label(11))
                    .foregroundColor(.white.opacity(0.85))
                    .textCase(.uppercase)
                Text(String(format: NSLocalizedString("Week %lld · Day %lld", comment: ""),
                            weekNumber, day.dayNumber))
                    .font(SBFont.heading(15))
                    .foregroundColor(.white)
            }
            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Background map

    private var mapBackground: some View {
        RunMapBackground(
            routeCoordinates: run.activeSession?.route.map(\.coordinate) ?? [],
            userLocation: location.lastLocation?.coordinate
        )
    }

    // MARK: - Controls panel

    private var controlsPanel: some View {
        VStack(spacing: 16) {
            switch location.authorizationStatus {
            case .notDetermined:
                permissionPrompt
            case .denied, .restricted:
                permissionBlocked
            default:
                if didFinish {
                    completionCard
                } else {
                    intervalCard
                    if canSkip { skipButton }
                    progressBar
                    statsRow
                    controlsRow
                }
            }
        }
        .padding(20)
        .padding(.bottom, 8)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var permissionPrompt: some View {
        VStack(spacing: 10) {
            Text(verbatim: PT("Location access needed"))
                .font(SBFont.heading(15))
                .foregroundColor(.sbTextPrimary)
            Text(verbatim: PT("PowerPump uses your location to trace your route and measure distance."))
                .font(SBFont.caption())
                .foregroundColor(.sbTextSecondary)
                .multilineTextAlignment(.center)
            SBPrimaryButton(title: "Allow Location") { location.requestAuthorization() }
        }
    }

    private var permissionBlocked: some View {
        VStack(spacing: 8) {
            Text(verbatim: PT("Location is off"))
                .font(SBFont.heading(15))
                .foregroundColor(.sbTextPrimary)
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text(verbatim: PT("Open Settings"))
                    .font(SBFont.body())
                    .fontWeight(.semibold)
                    .foregroundColor(.sbAccent)
            }
        }
    }

    private var current: ProgramInterval { day.intervals[currentIndex] }
    private var nextInterval: ProgramInterval? {
        currentIndex + 1 < day.intervals.count ? day.intervals[currentIndex + 1] : nil
    }
    private var remainingInCurrent: Int {
        max(0, current.duration - Int(elapsedInCurrent))
    }

    private var intervalCard: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: current.kind.icon)
                    .font(.system(size: 18, weight: .bold))
                Text(verbatim: PT(current.kind.labelKey))
                    .font(SBFont.heading(18))
                    .textCase(.uppercase)
            }
            .foregroundColor(.sbAccent)

            Text(formattedRemaining)
                .font(SBFont.display(56))
                .foregroundColor(.sbTextPrimary)
                .monospacedDigit()

            if let next = nextInterval {
                HStack(spacing: 6) {
                    Text(verbatim: PT("Next"))
                        .foregroundColor(.sbTextSecondary)
                    Image(systemName: next.kind.icon)
                        .foregroundColor(.sbTextSecondary)
                    Text(verbatim: PT(next.kind.labelKey))
                        .foregroundColor(.sbTextPrimary)
                        .fontWeight(.semibold)
                    Text("· \(formatted(seconds: next.duration))")
                        .foregroundColor(.sbTextSecondary)
                }
                .font(SBFont.caption())
            }
        }
    }

    /// Warm-up and cool-down can be skipped; the work in between can't.
    /// Any stretch can be skipped, from the start, before tapping Start too.
    private var canSkip: Bool { !didFinish }

    private var skipLabel: LocalizedStringKey {
        switch current.kind {
        case .warmup:   return "program.skip.warmup"
        case .cooldown: return "program.skip.cooldown"
        default:        return "program.skip.interval"
        }
    }

    private var skipButton: some View {
        Button {
            HapticManager.light()
            if !didStart { startSession() }
            if isPaused {
                // Resume so the next stretch starts counting right away.
                if let p = pauseStartedAt { pausedAccum += Date().timeIntervalSince(p) }
                pauseStartedAt = nil
                isPaused = false
                run.resume()
                startTimer()
            }
            let jump = TimeInterval(remainingInCurrent)
            if current.kind != .warmup && current.kind != .cooldown { skippedWork += jump }
            skipped += jump
            saveProgramContext()
            tick(0)
        } label: {
            Label(skipLabel, systemImage: "forward.end.fill")
                .font(SBFont.caption())
                .fontWeight(.semibold)
                .foregroundColor(.sbAccent)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(Color.sbAccentDim))
        }
        .buttonStyle(.plain)
    }

    private var progressBar: some View {
        let fraction = day.totalSeconds == 0 ? 0 : min(1, Double(position) / Double(day.totalSeconds))
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.sbSurfaceRaised)
                Capsule()
                    .fill(LinearGradient(colors: [.sbAccent, .sbAccent.opacity(0.6)],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: 6)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCell(title: "Total", value: formattedTotal)
            Divider().frame(height: 36)
            statCell(title: "Km", value: formattedKm)
            Divider().frame(height: 36)
            statCell(title: "kcal", value: "\(run.activeSession?.calories ?? 0)")
        }
    }

    private func statCell(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(SBFont.heading(18))
                .foregroundColor(.sbTextPrimary)
                .monospacedDigit()
            Text(verbatim: PT(title))
                .font(SBFont.label(9))
                .foregroundColor(.sbTextSecondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    private var controlsRow: some View {
        HStack(spacing: 16) {
            if !didStart {
                Button {
                    HapticManager.medium()
                    startSession()
                } label: {
                    Label(LocalizedStringKey("Start"), systemImage: "play.fill")
                        .font(SBFont.heading(16))
                        .fontWeight(.bold)
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
                    if isPaused {
                        if let p = pauseStartedAt {
                            pausedAccum += Date().timeIntervalSince(p)
                        }
                        pauseStartedAt = nil
                        coach.announceResume()
                        isPaused = false
                        run.resume()
                        startTimer()
                    } else {
                        pauseStartedAt = Date()
                        coach.announcePause()
                        isPaused = true
                        run.pause()
                        stopTimer()
                    }
                } label: {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
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
                    Label(LocalizedStringKey("Finish"), systemImage: "stop.fill")
                        .font(SBFont.heading(16))
                        .fontWeight(.bold)
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

    private var completionCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 38))
                .foregroundColor(.sbGreen)
            Text(verbatim: PT("Day complete!"))
                .font(SBFont.heading(20))
                .foregroundColor(.sbTextPrimary)
            Text(String(format: NSLocalizedString("You finished week %lld, day %lld.", comment: ""),
                        weekNumber, day.dayNumber))
                .font(SBFont.caption())
                .foregroundColor(.sbTextSecondary)
                .multilineTextAlignment(.center)
            SBPrimaryButton(title: "Done") {
                dismiss()
            }
        }
    }

    // MARK: - Lifecycle

    private func ensureAuth() {
        if location.authorizationStatus == .notDetermined { return }
    }

    private func startSession() {
        didStart = true
        isPaused = false
        currentIndex = 0
        elapsedInCurrent = 0
        totalElapsed = 0
        skipped = 0
        skippedWork = 0
        position = 0
        sessionStartedAt = Date()
        pausedAccum = 0
        pauseStartedAt = nil
        location.startTracking()
        run.start(activity: .run)
        saveProgramContext()
        coach.announceInterval(current, isFirst: true)
        coach.cueIntervalChange()
        startTimer()
    }

    /// Lets RunStore save which day this is and what was skipped, so the
    /// session can be reopened if the app is closed halfway.
    private func saveProgramContext() {
        run.setProgram(.init(programID: program.id, weekNumber: weekNumber,
                             dayNumber: day.dayNumber,
                             skipped: skipped, skippedWork: skippedWork))
    }

    /// Carries on a session the app was closed in the middle of: the clock
    /// comes from RunStore, the skips from its program context.
    private func resumeFromStore() {
        guard let timing = run.timing, run.activeSession != nil else { return }
        didStart = true
        sessionStartedAt = timing.startedAt
        pausedAccum = timing.pausedAccum
        pauseStartedAt = timing.pauseStartedAt
        isPaused = run.isPaused
        skipped = run.program?.skipped ?? 0
        skippedWork = run.program?.skippedWork ?? 0
        // Land on the right stretch without announcing each one passed.
        let now = timing.pauseStartedAt ?? Date()
        totalElapsed = max(0, now.timeIntervalSince(timing.startedAt) - timing.pausedAccum)
        position = totalElapsed + skipped
        var start: TimeInterval = 0
        var index = day.intervals.count - 1
        for (i, interval) in day.intervals.enumerated() {
            if position < start + TimeInterval(interval.duration) { index = i; break }
            if i == day.intervals.count - 1 { break }   // past the end: stay on the last
            start += TimeInterval(interval.duration)
        }
        currentIndex = index
        elapsedInCurrent = min(max(0, position - start), TimeInterval(current.duration))
        didAnnounceHalfway = true
        if !isPaused {
            startTimer()
            tick(0)
        }
    }

    private func completeAndDismiss() {
        stopTimer()
        location.stopTracking()
        let session = run.finish()
        // Stopping early keeps the run, but only a (nearly) finished session
        // completes the day: saving after one minute used to unlock the next
        // day, so the whole program could be skipped by accident.
        // A skipped warm-up counts as done: it's the work in between that matters.
        if day.totalSeconds == 0 || position - skippedWork >= Double(day.totalSeconds) * 0.8 {
            let globalDay = progress.globalDay(in: program,
                                               weekNumber: weekNumber,
                                               dayNumber: day.dayNumber)
            progress.markComplete(globalDay, in: program)
        }
        coach.announceFinish()
        coach.cueFinish()
        // Show summary if we got a real route, otherwise just dismiss.
        if let session, session.route.count >= 2 {
            finishedSession = session
        } else {
            dismiss()
        }
    }

    private func cancelAndDismiss() {
        stopTimer()
        location.stopTracking()
        run.discard()
        dismiss()
    }

    // MARK: - Timer

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor in tick(0.5) }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    @MainActor
    private func tick(_ dt: TimeInterval) {
        guard didStart, !isPaused, !didFinish, let start = sessionStartedAt else { return }

        // Compute total elapsed from the absolute start date. This is correct
        // whether the timer fired on time or after a long background gap.
        let realElapsed = max(0, Date().timeIntervalSince(start) - pausedAccum)
        totalElapsed = realElapsed
        position = realElapsed + skipped

        // Find which interval we're in by walking the cumulative durations.
        // If the user backgrounded the app long enough to skip past one or
        // more intervals, we'll advance through them sequentially below.
        var cumSum: TimeInterval = 0
        var newIndex = 0
        var newInCurrent: TimeInterval = 0
        for (i, interval) in day.intervals.enumerated() {
            let end = cumSum + TimeInterval(interval.duration)
            if position < end {
                newIndex = i
                newInCurrent = position - cumSum
                break
            }
            cumSum = end
            newIndex = i + 1
        }

        // We've walked past the last interval → session is finished.
        if newIndex >= day.intervals.count {
            elapsedInCurrent = TimeInterval(current.duration)
            stopTimer()
            didFinish = true
            location.stopTracking()
            let session = run.finish()
            let globalDay = progress.globalDay(in: program,
                                               weekNumber: weekNumber,
                                               dayNumber: day.dayNumber)
            // Skipping the walking and running doesn't count as doing the day.
            if position - skippedWork >= Double(day.totalSeconds) * 0.8 {
                progress.markComplete(globalDay, in: program)
            }
            coach.announceFinish()
            coach.cueFinish()
            if let session, session.route.count >= 2 {
                finishedSession = session
            }
            return
        }

        // Crossed into a new interval — announce it.
        if newIndex != currentIndex {
            currentIndex = newIndex
            didAnnounceHalfway = false
            didCountdown3 = false
            didCountdown2 = false
            didCountdown1 = false
            coach.announceInterval(current, isFirst: false)
            coach.cueIntervalChange()
        }
        elapsedInCurrent = newInCurrent

        let remaining = current.duration - Int(elapsedInCurrent)
        let half = current.duration / 2

        // Halfway announcement for intervals 60s or longer.
        if !didAnnounceHalfway && current.duration >= 60 && Int(elapsedInCurrent) >= half {
            didAnnounceHalfway = true
            coach.announceHalfway()
        }

        // Countdown ticks at 3, 2, 1.
        if !didCountdown3 && remaining == 3 { didCountdown3 = true; coach.cueCountdown() }
        if !didCountdown2 && remaining == 2 { didCountdown2 = true; coach.cueCountdown() }
        if !didCountdown1 && remaining == 1 { didCountdown1 = true; coach.cueCountdown() }
    }

    // (advanceInterval was removed — tick() now derives interval index from
    // absolute elapsed time so it self-heals after background gaps.)

    // MARK: - Formatting

    private var formattedRemaining: String {
        formatted(seconds: remainingInCurrent)
    }

    private var formattedTotal: String {
        formatted(seconds: Int(totalElapsed))
    }

    private var formattedKm: String {
        String(format: "%.2f", run.activeSession?.distanceKm ?? 0)
    }

    private func formatted(seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Background map (no follow camera, just visual context)

private struct RunMapBackground: UIViewRepresentable {
    let routeCoordinates: [CLLocationCoordinate2D]
    let userLocation: CLLocationCoordinate2D?

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.showsUserLocation = true
        map.userTrackingMode = .follow
        map.isPitchEnabled = false
        map.isRotateEnabled = false
        // Only a backdrop: a finger on it used to drag it away from the runner
        // and it stayed there. It just follows you now.
        map.isUserInteractionEnabled = false
        map.delegate = context.coordinator
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        if map.userTrackingMode != .follow { map.setUserTrackingMode(.follow, animated: true) }
        map.removeOverlays(map.overlays)
        if routeCoordinates.count >= 2 {
            let polyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
            map.addOverlay(polyline)
        }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let line = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
            let renderer = MKPolylineRenderer(polyline: line)
            renderer.strokeColor = UIColor(named: "AccentColor") ?? .systemBlue
            renderer.lineWidth = 5
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }
    }
}

