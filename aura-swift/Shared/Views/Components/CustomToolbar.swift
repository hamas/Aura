//
//  CustomToolbar.swift
//  Aura
//
//  Floating Progressive Blur Header Navigation Toolbar.
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
        ProgressiveBlurHeader(height: 84) {
            HStack(spacing: 16) {
                // Invisible balance spacer for true centering
                Button(action: {}) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.clear)
                }
                .disabled(true)
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Centered Brand Logo (Circle)
                Image("AuraLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                
                Spacer()
                
                // Search Bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search movies, shows...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .frame(maxWidth: 280)
                
                // Notification Icon on the Right
                Button(action: {}) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(PlainButtonStyle())
                
                // Profile Button
                Button(action: onProfileTap) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
    }
}

#Preview("Custom Toolbar") {
    ZStack {
        Color.black.ignoresSafeArea()
        CustomToolbar(searchText: .constant("")) {}
    }
    .frame(width: 800, height: 100)
}
