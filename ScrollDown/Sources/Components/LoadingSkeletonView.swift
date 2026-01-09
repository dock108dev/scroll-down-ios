import SwiftUI

/// Loading skeleton placeholder that resembles final content
/// Phase F: Replace generic spinners with intentional placeholders
struct LoadingSkeletonView: View {
    let style: SkeletonStyle
    @State private var isAnimating = false
    
    var body: some View {
        Group {
            switch style {
            case .gameCard:
                gameCardSkeleton
            case .timelineRow:
                timelineRowSkeleton
            case .socialPost:
                socialPostSkeleton
            case .textBlock:
                textBlockSkeleton
            case .list(let count):
                listSkeleton(count: count)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Skeleton Styles
    
    private var gameCardSkeleton: some View {
        VStack(alignment: .leading, spacing: Layout.cardSpacing) {
            // Teams
            HStack {
                skeletonBox(width: 80, height: 20)
                Text("at")
                    .font(.caption)
                    .foregroundColor(.secondary)
                skeletonBox(width: 80, height: 20)
            }
            
            // Status/time
            skeletonBox(width: 120, height: 16)
            
            // League badge
            skeletonBox(width: 60, height: 14)
        }
        .padding(Layout.cardPadding)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
    }
    
    private var timelineRowSkeleton: some View {
        HStack(alignment: .top, spacing: Layout.rowSpacing) {
            // Time
            skeletonBox(width: 48, height: 16)
            
            // Description
            VStack(alignment: .leading, spacing: Layout.smallSpacing) {
                skeletonBox(width: nil, height: 16)
                skeletonBox(width: 100, height: 14)
            }
        }
        .padding(Layout.rowPadding)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
    }
    
    private var socialPostSkeleton: some View {
        VStack(alignment: .leading, spacing: Layout.cardSpacing) {
            // Header
            HStack {
                skeletonBox(width: 60, height: 20)
                Spacer()
                skeletonBox(width: 40, height: 14)
            }
            
            // Content
            VStack(alignment: .leading, spacing: Layout.smallSpacing) {
                skeletonBox(width: nil, height: 16)
                skeletonBox(width: nil, height: 16)
                skeletonBox(width: 180, height: 16)
            }
        }
        .padding(Layout.cardPadding)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
    }
    
    private var textBlockSkeleton: some View {
        VStack(alignment: .leading, spacing: Layout.smallSpacing) {
            skeletonBox(width: nil, height: 16)
            skeletonBox(width: nil, height: 16)
            skeletonBox(width: 200, height: 16)
        }
    }
    
    private func listSkeleton(count: Int) -> some View {
        VStack(spacing: Layout.listSpacing) {
            ForEach(0..<count, id: \.self) { _ in
                timelineRowSkeleton
            }
        }
    }
    
    // MARK: - Helper
    
    private func skeletonBox(width: CGFloat?, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: Layout.skeletonCornerRadius)
            .fill(Color(.systemGray5))
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
            .opacity(isAnimating ? 0.5 : 1.0)
    }
}

enum SkeletonStyle {
    case gameCard
    case timelineRow
    case socialPost
    case textBlock
    case list(count: Int)
}

private enum Layout {
    static let cardSpacing: CGFloat = 10
    static let rowSpacing: CGFloat = 12
    static let smallSpacing: CGFloat = 6
    static let listSpacing: CGFloat = 12
    static let cardPadding: CGFloat = 14
    static let rowPadding: CGFloat = 12
    static let cornerRadius: CGFloat = 12
    static let skeletonCornerRadius: CGFloat = 4
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            Text("Game Card Skeleton")
                .font(.caption.weight(.semibold))
            LoadingSkeletonView(style: .gameCard)
            
            Text("Timeline Row Skeleton")
                .font(.caption.weight(.semibold))
            LoadingSkeletonView(style: .timelineRow)
            
            Text("Social Post Skeleton")
                .font(.caption.weight(.semibold))
            LoadingSkeletonView(style: .socialPost)
            
            Text("List Skeleton")
                .font(.caption.weight(.semibold))
            LoadingSkeletonView(style: .list(count: 3))
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
