import AVKit
import SwiftUI

// MARK: - Shared Social Media Preview

/// Reusable media preview that loads images via AsyncImage and shows video thumbnails
struct SocialMediaPreview: View {
    let imageUrl: String?
    let videoUrl: String?
    var postUrl: String? = nil
    var height: CGFloat = 200
    var tappable: Bool = true

    @State private var showingSafari = false

    var body: some View {
        Group {
            if let imageUrlString = imageUrl, let url = URL(string: imageUrlString) {
                let mediaContent = ZStack {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .overlay { ProgressView() }
                            .frame(height: height)
                    }
                    .frame(maxWidth: .infinity, minHeight: height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))

                    if videoUrl != nil {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 52, height: 52)
                            .overlay {
                                Image(systemName: "play.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                    }
                }

                if tappable {
                    Button {
                        showingSafari = true
                    } label: {
                        mediaContent
                    }
                    .buttonStyle(.plain)
                } else {
                    mediaContent
                }
            } else if let videoUrlString = videoUrl, let url = URL(string: videoUrlString) {
                InlineVideoPlayer(url: url)
            } else if videoUrl != nil, let postUrl {
                WatchOnXButton(postUrl: postUrl)
            }
        }
        .sheet(isPresented: $showingSafari) {
            if let postUrl, let url = URL(string: postUrl) {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }
}
