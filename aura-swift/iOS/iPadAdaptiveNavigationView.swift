//
//  iPadAdaptiveNavigationView.swift
//  Aura (iOS target)
//
//  Adaptive NavigationShell switching between iPhone MobileBottomTabBar and iPadOS NavigationSplitView sidebar.
//

import SwiftUI

#if os(iOS)
import UIKit

public struct iPadAdaptiveNavigationView: View {
    @State private var selectedTab: MobileTab = .home
    @State private var selectedDetailsItem: MediaItem? = nil
    @State private var longPressPreviewItem: MediaItem? = nil
    @State private var searchText: String = ""
    
    @EnvironmentObject private var playerManager: AVPlayerManager
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isIPad {
                // iPadOS SplitView Sidebar Navigation
                NavigationSplitView {
                    List {
                        ForEach(MobileTab.allCases) { tab in
                            Button(action: {
                                iOSHapticsManager.shared.triggerImpact(.light)
                                selectedTab = tab
                            }) {
                                Label(tab.rawValue, systemImage: tab.icon)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(selectedTab == tab ? .purple : .white)
                                    .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.sidebar)
                    .navigationTitle("Aura")
                } detail: {
                    tabContent
                }
            } else {
                // iPhone Mobile Bottom Navigation Bar Shell
                VStack(spacing: 0) {
                    tabContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    MobileBottomTabBar(selectedTab: $selectedTab)
                }
                .ignoresSafeArea(.keyboard)
            }
            
            // Fullscreen Long-Press Quick Action Overlay Modal
            if let previewItem = longPressPreviewItem {
                ZStack {
                    Color.black.opacity(0.65)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                longPressPreviewItem = nil
                            }
                        }
                    
                    PosterLongPressPreviewSheet(
                        item: previewItem,
                        onPlay: {
                            playerManager.loadMedia(previewItem)
                        },
                        onSelect: {
                            selectedDetailsItem = previewItem
                        },
                        onDismiss: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                longPressPreviewItem = nil
                            }
                        }
                    )
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
                .zIndex(50)
            }
        }
        .sheet(item: $selectedDetailsItem) { item in
            MediaDetailsView(
                item: item,
                onClose: {
                    selectedDetailsItem = nil
                },
                onPlayStream: { stream in
                    selectedDetailsItem = nil
                    playerManager.loadStream(item: item, option: stream)
                }
            )
        }
    }
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:
            MainFeedView()
        case .newAndHot:
            ClipsFeedView()
        case .library:
            LibraryView()
        case .search:
            SearchView(searchText: $searchText) { item in
                selectedDetailsItem = item
            }
        }
    }
}
#endif
