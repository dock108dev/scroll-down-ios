//
//  GameSimPlaybackView.swift
//  ScrollDown
//
//  Animated baseball diamond visualization of the most likely simulation outcome.
//  Shows silhouettes on bases, at-bat, and pitching with smooth animations.
//

import SwiftUI

struct GameSimPlaybackView: View {
    let result: SimulatorResult
    @State private var currentFrame = 0
    @State private var isPlaying = false
    @State private var homeScore = 0
    @State private var awayScore = 0

    /// Pre-computed "game replay" frames based on the most likely score
    private var frames: [SimFrame] {
        SimFrameGenerator.generate(from: result)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Scoreboard
            SimScoreboardView(
                awayTeam: result.awayTeam,
                homeTeam: result.homeTeam,
                awayScore: awayScore,
                homeScore: homeScore,
                inning: currentFrame < frames.count ? frames[currentFrame].inning : 9,
                isTopHalf: currentFrame < frames.count ? frames[currentFrame].isTopHalf : false
            )

            // Diamond
            DiamondFieldView(
                frame: currentFrame < frames.count ? frames[currentFrame] : SimFrame.empty
            )
            .frame(height: 280)

            // Play description
            if currentFrame < frames.count {
                Text(frames[currentFrame].description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(height: 36)
                    .padding(.horizontal)
                    .transition(.opacity)
                    .id(currentFrame) // force re-render on frame change
            }

            // Controls
            HStack(spacing: 24) {
                Button {
                    currentFrame = 0
                    homeScore = 0
                    awayScore = 0
                    isPlaying = false
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.title3)
                }
                .disabled(currentFrame == 0)

                Button {
                    if currentFrame > 0 { stepBack() }
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title3)
                }
                .disabled(currentFrame == 0)

                Button {
                    isPlaying.toggle()
                    if isPlaying { startPlayback() }
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(SimulatorTheme.homeColor)
                }

                Button {
                    if currentFrame < frames.count - 1 { stepForward() }
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                }
                .disabled(currentFrame >= frames.count - 1)

                // Speed indicator
                Text("\(currentFrame + 1)/\(frames.count)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 50)
            }
            .foregroundStyle(.primary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Playback

    private func startPlayback() {
        guard isPlaying else { return }
        guard currentFrame < frames.count - 1 else {
            isPlaying = false
            return
        }
        stepForward()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if isPlaying { startPlayback() }
        }
    }

    private func stepForward() {
        guard currentFrame < frames.count - 1 else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentFrame += 1
            let frame = frames[currentFrame]
            homeScore = frame.homeScoreSoFar
            awayScore = frame.awayScoreSoFar
        }
        HapticService.selection()
    }

    private func stepBack() {
        guard currentFrame > 0 else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentFrame -= 1
            let frame = frames[currentFrame]
            homeScore = frame.homeScoreSoFar
            awayScore = frame.awayScoreSoFar
        }
    }
}
