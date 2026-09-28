//
//  SharePlayCoordinator.swift
//  Aura
//
//  Created for Aura Media Suite on 2026-09-28.
//  Coordinates synchronized co-watching sessions via Apple GroupActivities and SharePlay.
//

import Foundation
import Combine
import AVFoundation
import GroupActivities

// MARK: - Aura CoWatch Activity Definition

public struct AuraCoWatchActivity: GroupActivity {
    public static let activityIdentifier = "app.aura.cowatch"
    
    public var metadata: GroupActivityMetadata {
        var meta = GroupActivityMetadata()
        meta.title = mediaTitle
        meta.subtitle = subtitle
        meta.type = .watchTogether
        meta.fallbackURL = URL(string: "https://aura.media/watch/\(mediaId)")
        return meta
    }
    
    public let mediaId: String
    public let mediaTitle: String
    public let subtitle: String
    public let streamUrlString: String
    
    public init(mediaId: String, mediaTitle: String, subtitle: String, streamUrlString: String) {
        self.mediaId = mediaId
        self.mediaTitle = mediaTitle
        self.subtitle = subtitle
        self.streamUrlString = streamUrlString
    }
}

// MARK: - SharePlay Coordinator Manager

@MainActor
public final class SharePlayCoordinator: ObservableObject {
    public static let shared = SharePlayCoordinator()
    
    @Published public private(set) var isSharePlayActive: Bool = false
    @Published public private(set) var participantCount: Int = 1
    @Published public private(set) var currentActivity: AuraCoWatchActivity?
    
    private var groupSession: GroupSession<AuraCoWatchActivity>?
    private var subscriptions = Set<AnyCancellable>()
    private var sessionSubscriptions = Set<AnyCancellable>()
    
    private init() {
        listenForGroupSessions()
    }
    
    // MARK: - Group Session Listener
    
    public func listenForGroupSessions() {
        Task {
            for await session in AuraCoWatchActivity.sessions() {
                self.configureGroupSession(session)
            }
        }
    }
    
    // MARK: - Start SharePlay Session
    
    public func startSession(mediaId: String, title: String, subtitle: String, streamUrl: String) async throws {
        let activity = AuraCoWatchActivity(
            mediaId: mediaId,
            mediaTitle: title,
            subtitle: subtitle,
            streamUrlString: streamUrl
        )
        
        switch await activity.prepareForActivation() {
        case .activationPreferred:
            _ = try await activity.activate()
        case .activationDisabled:
            print("[SharePlay] Activation disabled on this device.")
        case .cancelled:
            print("[SharePlay] SharePlay start cancelled by user.")
        @unknown default:
            break
        }
    }
    
    // MARK: - Leave Session
    
    public func endSession() {
        groupSession?.end()
        groupSession = nil
        isSharePlayActive = false
        participantCount = 1
        currentActivity = nil
        sessionSubscriptions.removeAll()
    }
    
    // MARK: - Coordinate with AVPlayer
    
    public func coordinate(with player: AVPlayer) {
        guard let session = groupSession else { return }
        player.playbackCoordinator.coordinateWithSession(session)
    }
    
    // MARK: - Private Configuration
    
    private func configureGroupSession(_ session: GroupSession<AuraCoWatchActivity>) {
        self.groupSession = session
        self.currentActivity = session.activity
        self.isSharePlayActive = true
        self.sessionSubscriptions.removeAll()
        
        session.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .invalidated:
                    self.endSession()
                case .joined:
                    self.isSharePlayActive = true
                case .waiting:
                    break
                @unknown default:
                    break
                }
            }
            .store(in: &sessionSubscriptions)
        
        session.$activeParticipants
            .receive(on: DispatchQueue.main)
            .sink { [weak self] participants in
                self?.participantCount = max(1, participants.count)
            }
            .store(in: &sessionSubscriptions)
        
        session.join()
    }
}
