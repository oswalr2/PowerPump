import SwiftUI
import ImageIO

// Loads and plays an animated GIF from a remote URL using native ImageIO.
// No third-party packages required.
struct GifPlayerView: View {
    let url: URL
    @StateObject private var loader = GifLoader()

    var body: some View {
        Group {
            if let frame = loader.currentFrame {
                Image(uiImage: frame)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ZStack {
                    Color.sbSurfaceRaised
                    SwiftUI.ProgressView().tint(.sbAccent)
                }
            }
        }
        .onAppear  { loader.load(from: url) }
        .onDisappear { loader.stop() }
    }
}

// MARK: - Frame decoder + animator

@MainActor
private final class GifLoader: ObservableObject {
    @Published var currentFrame: UIImage?

    private var frames:  [UIImage]      = []
    private var delays:  [TimeInterval] = []
    private var index    = 0
    private var timer:   Timer?
    private var loadTask: Task<Void, Never>?

    func load(from url: URL) {
        loadTask?.cancel()
        loadTask = Task { await fetchAndDecode(url: url) }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        loadTask?.cancel()
    }

    // MARK: - Private

    private func fetchAndDecode(url: URL) async {
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              !Task.isCancelled else { return }

        // Decode on a background thread
        let decoded: ([UIImage], [TimeInterval]) = await Task.detached(priority: .userInitiated) {
            guard let src = CGImageSourceCreateWithData(data as CFData, nil) else {
                return ([], [])
            }
            let count = CGImageSourceGetCount(src)
            var imgs:  [UIImage]      = []
            var dels:  [TimeInterval] = []
            for i in 0..<count {
                if let cg = CGImageSourceCreateImageAtIndex(src, i, nil) {
                    imgs.append(UIImage(cgImage: cg))
                    dels.append(GifLoader.gifDelay(source: src, index: i))
                }
            }
            return (imgs, dels)
        }.value

        guard !Task.isCancelled else { return }
        frames = decoded.0
        delays = decoded.1
        index  = 0
        tick()
    }

    private func tick() {
        guard !frames.isEmpty else { return }
        currentFrame = frames[index]
        let delay    = delays[index]
        index = (index + 1) % frames.count
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
    }

    nonisolated private static func gifDelay(source: CGImageSource, index: Int) -> TimeInterval {
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any],
              let gif   = props[kCGImagePropertyGIFDictionary as String] as? [String: Any]
        else { return 0.1 }
        let t = gif[kCGImagePropertyGIFUnclampedDelayTime as String] as? TimeInterval
             ?? gif[kCGImagePropertyGIFDelayTime          as String] as? TimeInterval
             ?? 0.1
        return max(t, 0.02)
    }
}
