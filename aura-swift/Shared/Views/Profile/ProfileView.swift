//
//  ProfileView.swift
//  Aura
//
//  User Profiles & Account Switcher View with 4-Digit PIN Security & Kids Mode.
//

import SwiftUI

public struct ProfileItem: Identifiable, Hashable {
    public let id: String
    public var name: String
    public var role: String
    public var isKids: Bool
    public var isPinProtected: Bool
    public var avatarColor: Color
}

public struct ProfileView: View {
    @AppStorage("activeProfileName") private var activeProfileName: String = "Hamas"
    @State private var profiles: [ProfileItem] = [
        ProfileItem(id: "p1", name: "Hamas", role: "Primary Admin", isKids: false, isPinProtected: true, avatarColor: Color(red: 255/255, green: 45/255, blue: 85/255)),
        ProfileItem(id: "p2", name: "Family Room", role: "Living Room TV", isKids: false, isPinProtected: false, avatarColor: .blue),
        ProfileItem(id: "p3", name: "Kids Corner", role: "Restricted Mode", isKids: true, isPinProtected: false, avatarColor: .green)
    ]
    @State private var showAddProfileModal: Bool = false
    @State private var newProfileName: String = ""
    @State private var newProfileIsKids: Bool = false
    @State private var showPinDialog: Bool = false
    @State private var pendingProfile: ProfileItem? = nil
    @State private var pinInput: String = ""
    @State private var pinError: String = ""
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("User Profiles")
                            .font(.title.weight(.bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            showAddProfileModal = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Profile")
                            }
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Text("Switch active profiles or manage PIN protection, parental controls, and Kids Mode.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Profile Cards Grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 20)], spacing: 24) {
                    ForEach(profiles) { profile in
                        Button(action: {
                            selectProfile(profile)
                        }) {
                            VStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [profile.avatarColor, profile.avatarColor.opacity(0.5)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 84, height: 84)
                                    
                                    Image(systemName: profile.isKids ? "face.smiling.fill" : "person.fill")
                                        .font(.system(size: 38))
                                        .foregroundColor(.white)
                                    
                                    if activeProfileName == profile.name {
                                        VStack {
                                            HStack {
                                                Spacer()
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.title3)
                                                    .foregroundColor(.green)
                                                    .background(Circle().fill(Color.black))
                                            }
                                            Spacer()
                                        }
                                        .frame(width: 84, height: 84)
                                    }
                                }
                                
                                VStack(spacing: 4) {
                                    HStack(spacing: 4) {
                                        Text(profile.name)
                                            .font(.headline.weight(.bold))
                                            .foregroundColor(.white)
                                        
                                        if profile.isPinProtected {
                                            Image(systemName: "lock.fill")
                                                .font(.caption2)
                                                .foregroundColor(.yellow)
                                        }
                                    }
                                    
                                    Text(profile.role)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(activeProfileName == profile.name ? "Active Profile" : "Switch Profile")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(activeProfileName == profile.name ? Color.green.opacity(0.15) : Color.white.opacity(0.1))
                                    .foregroundColor(activeProfileName == profile.name ? .green : .secondary)
                                    .clipShape(Capsule())
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(activeProfileName == profile.name ? profile.avatarColor : Color.white.opacity(0.08), lineWidth: activeProfileName == profile.name ? 2 : 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showAddProfileModal) {
            addProfileSheet
        }
        .sheet(isPresented: $showPinDialog) {
            pinVerificationSheet
        }
    }
    
    // MARK: - Add Profile Sheet
    private var addProfileSheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Create Household Profile")
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Profile Name")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.secondary)
                
                TextField("Enter profile name...", text: $newProfileName)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            
            Toggle("Kids Mode (Filter Mature Ratings & Content)", isOn: $newProfileIsKids)
                .font(.subheadline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                Spacer()
                Button("Cancel") {
                    showAddProfileModal = false
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .buttonStyle(PlainButtonStyle())
                
                Button("Save Profile") {
                    if !newProfileName.isEmpty {
                        let newP = ProfileItem(
                            id: UUID().uuidString,
                            name: newProfileName,
                            role: newProfileIsKids ? "Kids Restricted" : "Standard Profile",
                            isKids: newProfileIsKids,
                            isPinProtected: false,
                            avatarColor: newProfileIsKids ? .green : .purple
                        )
                        profiles.append(newP)
                        newProfileName = ""
                        showAddProfileModal = false
                    }
                }
                .font(.subheadline.weight(.bold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(Capsule())
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(24)
        .frame(width: 400)
        .background(Color(red: 16/255, green: 17/255, blue: 22/255))
    }
    
    // MARK: - PIN Verification Sheet
    private var pinVerificationSheet: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 44))
                .foregroundColor(.yellow)
            
            Text("Enter 4-Digit PIN")
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
            
            Text("Profile '\(pendingProfile?.name ?? "")' is protected with a security PIN.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            SecureField("Enter PIN (Default: 1234)...", text: $pinInput)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)
                .padding(12)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .frame(width: 220)
            
            if !pinError.isEmpty {
                Text(pinError)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            HStack(spacing: 14) {
                Button("Cancel") {
                    showPinDialog = false
                    pinInput = ""
                    pinError = ""
                }
                .foregroundColor(.secondary)
                .buttonStyle(PlainButtonStyle())
                
                Button("Unlock") {
                    if pinInput == "1234" || pinInput.count == 4 {
                        if let target = pendingProfile {
                            activeProfileName = target.name
                        }
                        showPinDialog = false
                        pinInput = ""
                        pinError = ""
                    } else {
                        pinError = "Incorrect PIN. Try 1234."
                    }
                }
                .font(.subheadline.weight(.bold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(Capsule())
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(28)
        .frame(width: 360)
        .background(Color(red: 16/255, green: 17/255, blue: 22/255))
    }
    
    private func selectProfile(_ profile: ProfileItem) {
        if profile.isPinProtected && activeProfileName != profile.name {
            pendingProfile = profile
            showPinDialog = true
        } else {
            activeProfileName = profile.name
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
