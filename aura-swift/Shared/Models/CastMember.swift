//
//  CastMember.swift
//  Aura
//
//  Model representing cast and crew metadata for details view.
//

import Foundation

public struct CastMember: Identifiable, Hashable, Codable {
    public let id: String
    public let name: String
    public let character: String
    public let profileURL: URL?
    
    public init(id: String, name: String, character: String, profileURL: URL?) {
        self.id = id
        self.name = name
        self.character = character
        self.profileURL = profileURL
    }
}
