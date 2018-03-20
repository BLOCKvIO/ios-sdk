//
//  Face.swift
//  BlockV
//
//  Created by Cameron McOnie on 2018/03/02.
//

import Foundation

/// Possible view modes a face may define for presentation.
public enum ViewMode: String {

    case icon       = "icon"
    case activated  = "activated"
    case fullscreen = "fullscreen"
    case card       = "card"
    case background = "background"
    
}

/// A simple struct that models a template face.
public struct Face: Codable {
    
    public let id: String
    public let templateName: String
    public let meta: MetaModel
    public let properties: Properties
    
    enum CodingKeys: String, CodingKey {
        case id
        case templateName = "template"
        case meta
        case properties
    }
    
    public struct Properties: Codable {
        
        public let displayURL: URL
        public let constraints: Constraints
        public let resources: [String]
        
        enum CodingKeys: String, CodingKey {
            case displayURL = "display_url"
            case constraints
            case resources
        }
        
        public struct Constraints: Codable {
            
            public let viewMode: String
            public let platform: String
            
            enum CodingKeys: String, CodingKey {
                case viewMode = "view_mode" //TODO: Map to view mode enum
                case platform
            }
            
        }
    }
    
}

// MARK: - Hashable

extension Face: Hashable {
    
    /// Faces are uniquely identified by their platform identifier.
    public var hashValue: Int {
        return id.hashValue
    }
    
}

// MARK: - Equatable

extension Face: Equatable {}

public func ==(lhs: Face, rhs: Face) -> Bool {
    return lhs.id == rhs.id &&
    lhs.templateName == rhs.templateName &&
    lhs.meta == rhs.meta &&
    lhs.properties == rhs.properties
    
}

extension Face.Properties: Equatable {}

public func ==(lhs: Face.Properties, rhs: Face.Properties) -> Bool {
    return lhs.displayURL == rhs.displayURL &&
    lhs.constraints == rhs.constraints &&
    lhs.resources == rhs.resources
}

extension Face.Properties.Constraints: Equatable {}

public func ==(lhs: Face.Properties.Constraints, rhs: Face.Properties.Constraints) -> Bool {
    return lhs.viewMode == rhs.viewMode &&
    lhs.platform == rhs.platform
}

