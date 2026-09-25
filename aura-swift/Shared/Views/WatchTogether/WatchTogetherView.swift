//
//  WatchTogetherView.swift
//  Aura
//
//  Watch Together (SyncPlay) Real-time synchronized playback rooms.
//

import SwiftUI

public struct WatchTogetherView: View {
    @State private var roomCodeInput: String = ""
    @State private var activeRooms: [String] = ["Aura Room #4092", "Sci-Fi Movie Night"]
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Watch Together")
                        .font(.title.weight(.bold))
                        .foregroundColor(.white)
                    
                    Text("Synchronize video playback and audio across devices in real time with low latency.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Join or Create Room Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.2.wave.2.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("Host or Join a Room")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 12) {
                        TextField("Enter 6-digit Room Code...", text: $roomCodeInput)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        
                        Button("Join") {}
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .buttonStyle(PlainButtonStyle())
                        
                        Button("Create New") {}
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                
                // Active Rooms Section
                VStack(alignment: .leading, spacing: 14) {
                    Text("ACTIVE FRIENDS' ROOMS")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                    
                    ForEach(activeRooms, id: \.self) { room in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(room)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white)
                                Text("3 members • Playing Dune: Part Two")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Connect") {}
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .foregroundColor(.white)
                                .buttonStyle(PlainButtonStyle())
                        }
                        .padding(16)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                    }
                }
            }
            .padding(.bottom, 40)
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
