import AVKit
import SwiftUI

/// Tap-to-play inline video player at 16:9 aspect ratio.
/// Shows a dark poster frame with a play button; tapping starts playback.
struct InlineVideoPlayer: View {
    let url: URL

    @State private var player: AVPlayer?
    @State private var isPlaying = false

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                // Poster frame placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .overlay {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 52, height: 52)
                            .overlay {
                                Image(systemName: "play.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                    }
                    .onTapGesture {
                        let avPlayer = AVPlayer(url: url)
                        player = avPlayer
                        isPlaying = true
                        avPlayer.play()
                    }
            }
        }
    }
}
