//
//  WatchTogetherView.swift
//  Aura
//
//  Watch Together (SyncPlay) Real-time synchronized playback rooms.
//

import SwiftUI

public struct WatchRoom: Identifiable {
    public let id = UUID()
    public let code: String
    public let name: String
    public let host: String
    public let membersCount: Int
    public let playingMedia: String
}

public struct WatchTogetherView: View {
    @EnvironmentObject private var playerManager: AVPlayerManager
    @State private var roomCodeInput: String = ""
    @State private var activeRoom: WatchRoom? = nil
    @State private var chatMessageInput: String = ""
    @State private var chatMessages: [String] = [
        "System: Room session synchronized (NTP offset: 12ms)",
        "Hamas: Hey everyone! Starting Dune in 1 minute."
    ]
    @State private var availableRooms: [WatchRoom] = [
        WatchRoom(code: "AURA-4092", name: "Aura Sci-Fi Room", host: "Hamas", membersCount: 3, playingMedia: "Dune: Part Two"),
        WatchRoom(code: "NIGHT-8821", name: "Cyberpunk Watch Party", host: "Elena", membersCount: 4, playingMedia: "Cyberpunk: Edgerunners"),
        WatchRoom(code: "CINEMA-102", name: "Weekend Blockbusters", host: "Marcus", membersCount: 2, playingMedia: "Oppenheimer")
    ]
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "person.2.wave.2.fill")
                            .font(.title2)
                            .foregroundColor(Color(red: 255/255, green: 45/255, blue: 85/255))
                        Text("Watch Together (SyncPlay)")
                            .font(.title.weight(.bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Synchronize video playback and audio across devices in real time with low latency.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                if let room = activeRoom {
                    // Active Room HUD & Live Sync Panel
                    activeRoomView(room)
                        .padding(.horizontal, 24)
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    // Join or Create Room Card
                    joinCreateRoomCard
                        .padding(.horizontal, 24)
                    
                    // Available Rooms List
                    availableRoomsSection
                        .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Join or Create Card
    private var joinCreateRoomCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "key.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                
                Text("Host or Join a Room")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 12) {
                TextField("Enter 6-digit Room Code (e.g. AURA-4092)...", text: $roomCodeInput)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                Button("Join") {
                    joinRoomByCode()
                }
                .font(.subheadline.weight(.bold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .buttonStyle(PlainButtonStyle())
                .disabled(roomCodeInput.isEmpty)
                
                Button("Create New") {
                    createNewRoom()
                }
                .font(.subheadline.weight(.bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(red: 255/255, green: 45/255, blue: 85/255))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    // MARK: - Available Rooms List
    private var availableRoomsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ACTIVE PUBLIC ROOMS")
                .font(.caption2.weight(.bold))
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                ForEach(availableRooms) { room in
                    HStack(spacing: 16) {
                        Image(systemName: "tv.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(Color(red: 0/255, green: 122/255, blue: 255/255))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(room.name)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.white)
                                
                                Text(room.code)
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            
                            Text("\(room.membersCount) members • Playing \(room.playingMedia)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Join Room") {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                activeRoom = room
                            }
                        }
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(16)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - Active Room View
    private func activeRoomView(_ room: WatchRoom) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            // Room Top Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(room.name)
                            .font(.title2.weight(.bold))
                            .foregroundColor(.white)
                        
                        Text(room.code)
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(red: 255/255, green: 45/255, blue: 85/255))
                            .clipShape(Capsule())
                    }
                    
                    Text("Host: \(room.host) • Playing: \(room.playingMedia)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Leave Room") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        activeRoom = nil
                    }
                }
                .font(.caption.weight(.bold))
                .foregroundColor(.red)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.red.opacity(0.15))
                .clipShape(Capsule())
                .buttonStyle(PlainButtonStyle())
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            // Sync Status & Host Controls
            HStack(spacing: 14) {
                Button(action: { playerManager.togglePlayPause() }) {
                    HStack(spacing: 8) {
                        Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                        Text(playerManager.isPlaying ? "Pause Sync" : "Play Sync")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
                
                Text("Sync Clock: NTP 14ms (Optimal)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
            }
            
            // Live Chat Panel
            VStack(alignment: .leading, spacing: 12) {
                Text("ROOM LIVE CHAT")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(chatMessages, id: \.self) { msg in
                        Text(msg)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                HStack(spacing: 10) {
                    TextField("Type chat message...", text: $chatMessageInput)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.subheadline)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    
                    Button("Send") {
                        if !chatMessageInput.isEmpty {
                            chatMessages.append("Hamas: \(chatMessageInput)")
                            chatMessageInput = ""
                        }
                    }
                    .font(.caption.weight(.bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(18)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
    
    private func joinRoomByCode() {
        let room = WatchRoom(
            code: roomCodeInput.uppercased(),
            name: "Room \(roomCodeInput.uppercased())",
            host: "Friend Host",
            membersCount: 2,
            playingMedia: "Media Stream"
        )
        withAnimation(.easeInOut(duration: 0.25)) {
            activeRoom = room
        }
        roomCodeInput = ""
    }
    
    private func createNewRoom() {
        let randomCode = "AURA-\(Int.random(in: 1000...9999))"
        let newRoom = WatchRoom(
            code: randomCode,
            name: "Hamas's Private Room",
            host: "Hamas (You)",
            membersCount: 1,
            playingMedia: "Dune: Part Two"
        )
        withAnimation(.easeInOut(duration: 0.25)) {
            activeRoom = newRoom
        }
    }
}

#Preview("Watch Together View") {
    ZStack {
        Color(red: 13/255, green: 14/255, blue: 18/255)
            .ignoresSafeArea()
        WatchTogetherView()
    }
}
