//
//  RealtimeService.swift
//  ScrollDown
//
//  WebSocket-based realtime updates with exponential backoff reconnect.
//

import Foundation
import Combine

@MainActor
final class RealtimeService: ObservableObject {
    static let shared = RealtimeService()

    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastEvent: RealtimeEvent?

    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession
    private var reconnectAttempt = 0
    private var reconnectTask: Task<Void, Never>?
    private var subscribedChannels: Set<String> = []
    private var failCount = 0
    private var failWindowStart: Date?

    private static let maxBackoffSeconds: Double = 30
    private static let initialBackoffSeconds: Double = 1
    private static let failThreshold = 2
    private static let failWindowSeconds: TimeInterval = 60

    private init() {
        self.session = URLSession(configuration: .default)
    }

    // MARK: - Connect

    func connect() {
        guard webSocketTask == nil else { return }

        let baseURL = AppConfig.shared.apiBaseURL
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return }
        components.scheme = components.scheme == "https" ? "wss" : "ws"
        components.path = "/v1/ws"

        guard let url = components.url else { return }

        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        connectionState = .connected
        reconnectAttempt = 0

        receiveMessages()

        // Re-subscribe to any channels
        for channel in subscribedChannels {
            sendSubscribe(channel: channel)
        }
    }

    func disconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        connectionState = .disconnected
    }

    // MARK: - Subscribe

    func subscribe(channel: String) {
        subscribedChannels.insert(channel)
        sendSubscribe(channel: channel)
    }

    func unsubscribe(channel: String) {
        subscribedChannels.remove(channel)
        let message = """
        {"action":"unsubscribe","channel":"\(channel)"}
        """
        webSocketTask?.send(.string(message)) { _ in }
    }

    // MARK: - Private

    private func sendSubscribe(channel: String) {
        let message = """
        {"action":"subscribe","channel":"\(channel)"}
        """
        webSocketTask?.send(.string(message)) { _ in }
    }

    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let message):
                    self.handleMessage(message)
                    self.receiveMessages() // Continue listening
                case .failure:
                    self.handleDisconnect()
                }
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            guard let data = text.data(using: .utf8) else { return }
            if let event = try? JSONDecoder().decode(RealtimeEvent.self, from: data) {
                lastEvent = event
            }
        case .data(let data):
            if let event = try? JSONDecoder().decode(RealtimeEvent.self, from: data) {
                lastEvent = event
            }
        @unknown default:
            break
        }
    }

    private func handleDisconnect() {
        webSocketTask = nil
        connectionState = .disconnected

        // Track failures for fallback
        let now = Date()
        if let start = failWindowStart, now.timeIntervalSince(start) > Self.failWindowSeconds {
            failCount = 0
            failWindowStart = now
        }
        if failWindowStart == nil { failWindowStart = now }
        failCount += 1

        if failCount >= Self.failThreshold {
            connectionState = .degraded
        }

        // Exponential backoff reconnect
        let delay = min(
            Self.maxBackoffSeconds,
            Self.initialBackoffSeconds * pow(2, Double(reconnectAttempt))
        )
        reconnectAttempt += 1

        reconnectTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self.connect()
        }
    }
}
