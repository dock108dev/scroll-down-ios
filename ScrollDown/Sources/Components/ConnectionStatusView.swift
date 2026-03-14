//
//  ConnectionStatusView.swift
//  ScrollDown
//
//  Green/yellow/red dot for realtime connection status.
//

import SwiftUI

enum ConnectionState {
    case connected, degraded, disconnected

    var color: Color {
        switch self {
        case .connected: return .green
        case .degraded: return .yellow
        case .disconnected: return .red
        }
    }

    var label: String {
        switch self {
        case .connected: return "Connected"
        case .degraded: return "Reconnecting"
        case .disconnected: return "Offline"
        }
    }
}

struct ConnectionStatusView: View {
    let state: ConnectionState

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(state.color)
                .frame(width: 6, height: 6)
            Text(state.label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
