//
//  MacOSSidebarView.swift
//  Aura (macOS target)
//
//  Apple TV-style translucent blurred sidebar with blue line icons and bottom profile/settings footer.
//

import SwiftUI

#if os(macOS)
public enum SidebarSection: String, CaseIterable, Identifiable, Hashable {
    case search = "Search"
    case home = "Home"
    case clips = "Clips"
    case movies = "Movies"
    case tvShows = "TV Shows"
    case categories = "Categories"
    
    // Social & Extensions
    case watchTogether = "Watch Together"
    case addons = "Add-ons"
    
    // Library
    case wishlist = "Wishlist"
    case downloads = "Downloads"
    case watchlist = "Watchlist"
    case history = "History"
    
    case profile = "Profile"
    case settings = "Settings"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .search: return "magnifyingglass"
        case .home: return "house"
        case .clips: return "film.stack"
        case .movies: return "film"
        case .tvShows: return "tv"
        case .categories: return "square.grid.2x2"
            
        case .watchTogether: return "person.2.wave.2"
        case .addons: return "puzzlepiece"
            
        case .wishlist: return "heart"
        case .downloads: return "arrow.down.circle"
        case .watchlist: return "bookmark"
        case .history: return "clock"
            
        case .profile: return "person.crop.circle"
        case .settings: return "gearshape"
        }
    }
}

public struct MacOSSidebarView: View {
    @Binding public var selectedSection: SidebarSection?
    @Binding public var searchText: String
    
    public init(selectedSection: Binding<SidebarSection?>, searchText: Binding<String>) {
        self._selectedSection = selectedSection
        self._searchText = searchText
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top Margin for macOS Window Traffic Lights (Red, Yellow, Green)
            Spacer()
                .frame(height: 38)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 3) {
                    // Top Navigation Items
                    SidebarRowButton(section: .search, isSelected: selectedSection == .search) {
                        selectedSection = .search
                    }
                    SidebarRowButton(section: .home, isSelected: selectedSection == .home) {
                        selectedSection = .home
                    }
                    SidebarRowButton(section: .clips, isSelected: selectedSection == .clips) {
                        selectedSection = .clips
                    }
                    SidebarRowButton(section: .movies, isSelected: selectedSection == .movies) {
                        selectedSection = .movies
                    }
                    SidebarRowButton(section: .tvShows, isSelected: selectedSection == .tvShows) {
                        selectedSection = .tvShows
                    }
                    SidebarRowButton(section: .categories, isSelected: selectedSection == .categories) {
                        selectedSection = .categories
                    }
                    
                    // Social & Protocol Addons Section Header
                    Text("Ecosystem")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 14)
                        .padding(.top, 14)
                        .padding(.bottom, 4)
                    
                    SidebarRowButton(section: .watchTogether, isSelected: selectedSection == .watchTogether) {
                        selectedSection = .watchTogether
                    }
                    SidebarRowButton(section: .addons, isSelected: selectedSection == .addons) {
                        selectedSection = .addons
                    }
                    
                    // Library Section Header
                    Text("Library")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 14)
                        .padding(.top, 14)
                        .padding(.bottom, 4)
                    
                    // Library Navigation Items
                    SidebarRowButton(section: .wishlist, isSelected: selectedSection == .wishlist) {
                        selectedSection = .wishlist
                    }
                    SidebarRowButton(section: .downloads, isSelected: selectedSection == .downloads) {
                        selectedSection = .downloads
                    }
                    SidebarRowButton(section: .watchlist, isSelected: selectedSection == .watchlist) {
                        selectedSection = .watchlist
                    }
                    SidebarRowButton(section: .history, isSelected: selectedSection == .history) {
                        selectedSection = .history
                    }
                }
                .padding(.horizontal, 10)
            }
            
            Spacer(minLength: 10)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Bottom Sidebar Footer: Profile Avatar & Settings Button
            HStack(spacing: 10) {
                Button(action: {
                    selectedSection = .profile
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(selectedSection == .profile ? Color(red: 255/255, green: 45/255, blue: 85/255) : .white)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Hamas")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text("Primary Profile")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button(action: {
                    selectedSection = .settings
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 15))
                        .foregroundColor(selectedSection == .settings ? .white : .secondary)
                        .padding(6)
                        .background(
                            Group {
                                if selectedSection == .settings {
                                    Circle().fill(Color(red: 0/255, green: 122/255, blue: 255/255))
                                } else {
                                    Color.clear
                                }
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.15))
        }
        .frame(minWidth: 210, maxWidth: 240)
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
    }
}

struct SidebarRowButton: View {
    let section: SidebarSection
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: section.iconName)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(isSelected ? .white : Color(red: 0/255, green: 122/255, blue: 255/255))
                    .frame(width: 20)
                
                Text(section.rawValue)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.9))
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(red: 0/255, green: 122/255, blue: 255/255))
                    } else if isHovered {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview("macOS Sidebar View") {
    MacOSSidebarView(selectedSection: .constant(.home), searchText: .constant(""))
        .frame(width: 240, height: 700)
}
#endif
