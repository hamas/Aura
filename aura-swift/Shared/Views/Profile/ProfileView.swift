//
//  ProfileView.swift
//  Aura
//
//  User Profiles & Account Switcher View.
//

import SwiftUI

public struct ProfileItem: Identifiable {
    public let id = UUID()
    public let name: String
    public let role: String
    public let isKids: Bool
}

public struct ProfileView: View {
    @State private var profiles: [ProfileItem] = [
        ProfileItem(name: "Apple User", role: "Main Account", isKids: false),
        ProfileItem(name: "Family Room", role: "Living Room TV", isKids: false),
        ProfileItem(name: "Kids Corner", role: "Restricted Mode", isKids: true)
    ]
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("User Profiles")
                        .font(.title.weight(.bold))
                        .foregroundColor(.white)
                    Text("Switch active profiles or manage PIN protection and Kids Mode.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                HStack(spacing: 20) {
                    ForEach(profiles) { profile in
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(white: 0.25), Color(white: 0.12)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: profile.isKids ? "face.smiling.fill" : "person.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 2) {
                                Text(profile.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white)
                                Text(profile.role)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
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
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 40)
        }
    }
}

#Preview("Profile View") {
    ZStack {
        Color(red: 13/255, green: 14/255, blue: 18/255)
            .ignoresSafeArea()
        ProfileView()
    }
}
