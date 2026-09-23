//
//  CustomToolbar.swift
//  Aura
//
//  Floating Glassmorphic Header Navigation Toolbar.
//

import SwiftUI

public struct CustomToolbar: View {
    @Binding public var searchText: String
    public var onProfileTap: () -> Void
    
    public init(searchText: Binding<String>, onProfileTap: @escaping () -> Void) {
        self._searchText = searchText
        self.onProfileTap = onProfileTap
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            // Brand Logo & Title
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("AURA")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .tracking(2.5)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color.white.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            Spacer()
            
            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search movies, shows, genres...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .frame(maxWidth: 320)
            
            // Profile Avatar Button
            Button(action: onProfileTap) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white.opacity(0.9))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .liquidGlass(cornerRadius: 22, opacity: 0.75)
        .padding(.horizontal)
    }
}
