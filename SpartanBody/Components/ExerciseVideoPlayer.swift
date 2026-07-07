import SwiftUI
import AVKit

// Plays a bundled MP4 in a seamless loop with no controls.
struct ExerciseVideoPlayer: View {
    let videoName: String   // filename without extension, e.g. "bench_press"

    @StateObject private var player = LoopingPlayer()

    var body: some View {
        Group {
            if player.isReady {
                VideoPlayerLayer(player: player.avPlayer)
            } else {
                // Fallback while loading
                Color.sbSurface
                    .overlay(
                        SwiftUI.ProgressView().tint(.sbAccent)
                    )
            }
        }
        .onAppear  { player.load(videoName) }
        .onDisappear { player.pause() }
    }
}

// MARK: - UIKit bridge for AVPlayer (no controls, fills frame)

private struct VideoPlayerLayer: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.player = player
        return view
    }
    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.player = player
    }
}

final class PlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    var player: AVPlayer? {
        get { playerLayer.player }
        set {
            playerLayer.player = newValue
            playerLayer.videoGravity = .resizeAspect
        }
    }
}

// MARK: - Looping player model

@MainActor
final class LoopingPlayer: ObservableObject {
    @Published var isReady = false
    let avPlayer = AVPlayer()
    private var loopObserver: NSObjectProtocol?

    func load(_ name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp4") else {
            return
        }
        let item = AVPlayerItem(url: url)
        avPlayer.replaceCurrentItem(with: item)
        avPlayer.isMuted = true
        avPlayer.play()
        isReady = true

        // Loop forever
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.avPlayer.seek(to: .zero)
            self?.avPlayer.play()
        }
    }

    func pause() {
        avPlayer.pause()
        if let obs = loopObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }
}
