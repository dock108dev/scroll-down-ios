//
//  LiveGameHeader.swift
//  ScrollDown
//
//  Matchup header for live game odds section with pulsing live dot.
//

import SwiftUI

struct LiveGameHeader: View {
    let game: LiveGameInfo
    let betCount: Int

    @State private var dotOpacity: Double = 1.0

    var body: some View {
        HStack(spacing: 8) {
            // Pulsing live dot
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
                .opacity(dotOpacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        dotOpacity = 0.3
                    }
                }

            Text("LIVE")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.red)

            Text(game.awayTeam)
                .font(.subheadline.weight(.semibold))
            Text("@")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(game.homeTeam)
                .font(.subheadline.weight(.semibold))

            Spacer()

            Text("\(betCount) bets")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
