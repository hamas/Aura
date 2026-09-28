//
//  MobileBottomTabBar.swift
//  Aura (iOS target)
//
//  Signature frosted Netflix-grade mobile bottom navigation tab bar.
//

import SwiftUI

public enum MobileTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case newAndHot = "New & Hot"
    case library = "My Netflix"
    case search = "Search"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .home: return "house.fill"
        case .newAndHot: return "play.rectangle.on.rectangle.fill"
        case .library: return "square.stack.3d.down.right.fill"
        case .search: return "magnifyingglass"
        }
    }
}

#if os(iOS)
public struct MobileBottomTabBar: View {
    @Binding public var selectedTab: MobileTab
    
    public init(selectedTab: Binding<MobileTab>) {
        self._selectedTab = selectedTab
    }
    
    public var body: some View {
        HStack {
            ForEach(MobileTab.allCases) { tab in
                let isSelected = selectedTab == tab
                
                Button(action: {
                    if selectedTab != tab {
                        iOSHapticsManager.shared.triggerImpact(.light)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: isSelected ? 20 : 18, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? .white : .white.opacity(0.45))
                            .scaleEffect(isSelected ? 1.08 : 1.0)
                        
                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                            .foregroundColor(isSelected ? .white : .white.opacity(0.45))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 2)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                        .padding(.top, -0.5),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
#endif
