//
//  MediaDetailsView.swift
//  Aura
//
//  Single Page Media Details view with poster, logo, synopsis, metadata, real cast & dynamic stream quality picker.
//

import SwiftUI

public struct MediaDetailsView: View {
    let item: MediaItem
    let onClose: () -> Void
    let onPlayStream: (StreamOption) -> Void
    
    @EnvironmentObject private var playerManager: AVPlayerManager
    @State private var selectedStream: StreamOption?
    @State private var streamOptions: [StreamOption] = []
    @State private var castMembers: [CastMember] = []
    @State private var detailedLogoURL: URL?
    @State private var detailedOverview: String = ""
    @State private var detailedGenres: [String] = []
    @State private var detailedRuntime: Double = 7200
    @State private var isBookmarked: Bool = false
    @State private var isLoadingStreams: Bool = true
    @State private var isLoadingDetails: Bool = true
    
    public init(
        item: MediaItem,
        onClose: @escaping () -> Void,
        onPlayStream: @escaping (StreamOption) -> Void
    ) {
        self.item = item
        self.onClose = onClose
        self.onPlayStream = onPlayStream
        self._selectedStream = State(initialValue: nil)
        self._detailedLogoURL = State(initialValue: item.logoURL)
        self._detailedOverview = State(initialValue: item.description)
        self._detailedGenres = State(initialValue: item.genres)
        self._detailedRuntime = State(initialValue: item.durationSeconds)
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            // Dark Background
            Color(red: 10/255, green: 11/255, blue: 15/255)
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: - Hero Backdrop & Cover Section
                    heroBackdropSection
                    
                    // MARK: - Content Body
                    VStack(alignment: .leading, spacing: 28) {
                        // Title & Metadata Header
                        titleMetadataSection
                        
                        // Action Bar (Play Primary + Favorite)
                        actionButtonsRow
                        
                        Divider()
                            .background(Color.white.opacity(0.12))
                        
                        // Synopsis / Plot Description
                        synopsisSection
                        
                        // Cast & Crew Row
                        castSection
                        
                        Divider()
                            .background(Color.white.opacity(0.12))
                        
                        // Stream Quality & Source Picker
                        streamPickerSection
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 20)
                    .padding(.bottom, 60)
                }
            }
            .ignoresSafeArea(.all, edges: .top)
            
            // MARK: - Sticky Top Navigation Controls
            headerBar
        }
        .preferredColorScheme(.dark)
        .task {
            await loadDetailsAndStreams()
        }
    }
    
    private func loadDetailsAndStreams() async {
        // 1. Fetch deep details from TMDB (credits, logos, IMDb ID)
        let isMovie = !item.subtitle.lowercased().contains("series") && !item.subtitle.lowercased().contains("season")
        let details = await APIClient.shared.fetchDetails(id: item.id, isMovie: isMovie)
        
        withAnimation(.easeInOut(duration: 0.25)) {
            if let logo = details.logoURL {
                self.detailedLogoURL = logo
            }
            if !details.cast.isEmpty {
                self.castMembers = details.cast
            }
            if let overview = details.description, !overview.isEmpty {
                self.detailedOverview = overview
            }
            if !details.genres.isEmpty {
                self.detailedGenres = details.genres
            }
            if details.runtimeSeconds > 0 {
                self.detailedRuntime = details.runtimeSeconds
            }
            self.isLoadingDetails = false
        }
        
        // 2. Fetch real streams from Torrentio & Debrid
        let streams = await APIClient.shared.fetchStreams(
            imdbId: details.imdbId,
            title: item.title,
            year: item.releaseYear,
            type: isMovie ? "movie" : "series"
        )
        
        withAnimation(.easeInOut(duration: 0.25)) {
            self.streamOptions = streams
            self.selectedStream = streams.first
            self.isLoadingStreams = false
        }
    }
    
    // MARK: - Hero Backdrop
    private var heroBackdropSection: some View {
        ZStack(alignment: .bottomLeading) {
            if let backdrop = item.backdropURL {
                AsyncImage(url: backdrop) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 420)
                            .clipped()
                    default:
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 420)
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 420)
            }
            
            // Multi-stage Dark Gradient & Backdrop Vignette Mask
            LinearGradient(
                colors: [
                    Color.black.opacity(0.4),
                    Color.clear,
                    Color(red: 10/255, green: 11/255, blue: 15/255).opacity(0.85),
                    Color(red: 10/255, green: 11/255, blue: 15/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 420)
        }
        .frame(height: 420)
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            // Close / Back Button
            Button(action: onClose) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                    Text("Back")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Bookmark Button
            Button(action: { isBookmarked.toggle() }) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isBookmarked ? .purple : .white)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    // MARK: - Title & Badges Section
    private var titleMetadataSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Logo Image or Title Text
            if let logoURL = detailedLogoURL {
                AsyncImage(url: logoURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 75, alignment: .leading)
                    } else {
                        Text(item.title)
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            } else {
                Text(item.title)
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // Metadata Badges Row
            HStack(spacing: 12) {
                // Rating Badge
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.yellow)
                    Text(item.rating)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.yellow.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // Release Year
                Text(item.releaseYear)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // Duration
                let hours = Int(detailedRuntime) / 3600
                let mins = (Int(detailedRuntime) % 3600) / 60
                Text("\(hours)h \(mins)m")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // Quality Tech Badges
                if item.is4K {
                    Text("4K ULTRA HD")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.purple.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                if item.isHDR {
                    Text("HDR10+")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            
            // Genres Row
            HStack(spacing: 8) {
                ForEach(detailedGenres.isEmpty ? item.genres : detailedGenres, id: \.self) { genre in
                    Text(genre)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
            }
        }
    }
    
    // MARK: - Action Buttons Row
    private var actionButtonsRow: some View {
        HStack(spacing: 16) {
            Button(action: {
                if let stream = selectedStream {
                    onPlayStream(stream)
                }
            }) {
                HStack(spacing: 10) {
                    if isLoadingStreams {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .bold))
                    }
                    
                    Text(isLoadingStreams ? "Fetching Streams..." : "Play \(selectedStream?.quality ?? "Stream")")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.purple, Color.indigo],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.purple.opacity(0.4), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isLoadingStreams && selectedStream == nil)
        }
    }
    
    // MARK: - Synopsis Section
    private var synopsisSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Synopsis")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(detailedOverview.isEmpty ? item.description : detailedOverview)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.78))
                .lineSpacing(5)
        }
    }
    
    // MARK: - Cast & Crew Section
    private var castSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Cast & Crew")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            if castMembers.isEmpty && isLoadingDetails {
                HStack(spacing: 16) {
                    ForEach(0..<4, id: \.self) { _ in
                        VStack(spacing: 8) {
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 64, height: 64)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 60, height: 12)
                        }
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(castMembers.isEmpty ? item.castMembers : castMembers) { cast in
                            VStack(spacing: 8) {
                                if let profileURL = cast.profileURL {
                                    AsyncImage(url: profileURL) { phase in
                                        switch phase {
                                        case .success(let img):
                                            img
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 64, height: 64)
                                                .clipShape(Circle())
                                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                                        default:
                                            castFallbackAvatar
                                        }
                                    }
                                } else {
                                    castFallbackAvatar
                                }
                                
                                VStack(spacing: 2) {
                                    Text(cast.name)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    Text(cast.character)
                                        .font(.system(size: 10, weight: .regular))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                .frame(width: 80)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var castFallbackAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 64, height: 64)
            
            Image(systemName: "person.fill")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.5))
        }
    }
    
    // MARK: - Stream Quality & Source Picker
    private var streamPickerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Select Stream & Quality")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Choose your preferred bitrate, resolution, and P2P/Debrid provider")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                if isLoadingStreams {
                    HStack(spacing: 6) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                            .scaleEffect(0.7)
                        Text("Scraping Swarms...")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.purple)
                    }
                }
            }
            
            let displayStreams = streamOptions.isEmpty ? item.streamOptions : streamOptions
            
            VStack(spacing: 12) {
                ForEach(displayStreams) { option in
                    let isSelected = selectedStream?.id == option.id
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedStream = option
                        }
                    }) {
                        HStack(spacing: 16) {
                            // Selection Indicator Radio Circle
                            ZStack {
                                Circle()
                                    .stroke(isSelected ? Color.purple : Color.white.opacity(0.3), lineWidth: 2)
                                    .frame(width: 20, height: 20)
                                
                                if isSelected {
                                    Circle()
                                        .fill(Color.purple)
                                        .frame(width: 12, height: 12)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 10) {
                                    Text(option.quality)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(option.provider)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(option.provider.contains("Real-Debrid") ? .yellow : .cyan)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(
                                            (option.provider.contains("Real-Debrid") ? Color.yellow : Color.cyan).opacity(0.15)
                                        )
                                        .clipShape(Capsule())
                                }
                                
                                HStack(spacing: 12) {
                                    Text(option.codec)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text("•")
                                        .foregroundColor(.white.opacity(0.3))
                                    
                                    Text(option.audio)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text("•")
                                        .foregroundColor(.white.opacity(0.3))
                                    
                                    Text(option.size)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.purple.opacity(0.9))
                                }
                            }
                            
                            Spacer()
                            
                            // Seeders & Leechers Pill
                            VStack(alignment: .trailing, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text("🌱 \(option.seeders)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.green)
                                    
                                    Text("📥 \(option.leechers)")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.orange)
                                }
                                
                                Text(option.resolution)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isSelected ? Color.purple.opacity(0.18) : Color.white.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isSelected ? Color.purple : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

#Preview("Media Details View") {
    MediaDetailsView(
        item: MediaItem.sampleHero,
        onClose: {},
        onPlayStream: { _ in }
    )
    .environmentObject(AVPlayerManager())
    .frame(width: 850, height: 750)
}
