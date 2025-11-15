//
//  SkillTree.swift
//  Growth Map
//
//  Created on November 15, 2025.
//

import Foundation

/// Represents a skill tree for a goal
/// Mirrors the `skill_trees` table in the database
struct SkillTree: Identifiable, Codable, Equatable {
    let id: UUID
    let goalId: UUID
    let treeJson: [String: AnyCodable]
    let generatedBy: String
    let version: Int
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case goalId = "goal_id"
        case treeJson = "tree_json"
        case generatedBy = "generated_by"
        case version
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Represents a node within a skill tree
/// Mirrors the `skill_tree_nodes` table in the database
struct SkillTreeNode: Identifiable, Codable, Equatable {
    let id: UUID
    let skillTreeId: UUID
    let nodePath: String
    let title: String
    let level: Int
    let focusHours: Double
    let payload: [String: AnyCodable]
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case skillTreeId = "skill_tree_id"
        case nodePath = "node_path"
        case title
        case level
        case focusHours = "focus_hours"
        case payload
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Draft structure for skill tree nodes (used in Edge Functions)
struct SkillTreeNodeDraft: Codable {
    let nodePath: String
    let title: String
    let level: Int
    let focusHours: Double
    let payload: [String: AnyCodable]
    
    enum CodingKeys: String, CodingKey {
        case nodePath = "node_path"
        case title
        case level
        case focusHours = "focus_hours"
        case payload
    }
}

/// Draft structure for skill tree (used in Edge Functions)
struct SkillTreeDraft: Codable {
    let treeJson: [String: AnyCodable]
    let nodes: [SkillTreeNodeDraft]
    
    enum CodingKeys: String, CodingKey {
        case treeJson = "tree_json"
        case nodes
    }
}

/// Skill tree with its nodes combined
struct SkillTreeWithNodes: Equatable {
    let skillTree: SkillTree
    let nodes: [SkillTreeNode]
}

extension SkillTreeWithNodes: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode base skill tree fields
        let id = try container.decode(UUID.self, forKey: .id)
        let goalId = try container.decode(UUID.self, forKey: .goalId)
        let treeJson = try container.decode([String: AnyCodable].self, forKey: .treeJson)
        let generatedBy = try container.decode(String.self, forKey: .generatedBy)
        let version = try container.decode(Int.self, forKey: .version)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        let updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        self.skillTree = SkillTree(
            id: id,
            goalId: goalId,
            treeJson: treeJson,
            generatedBy: generatedBy,
            version: version,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        
        // Decode nodes array
        self.nodes = try container.decode([SkillTreeNode].self, forKey: .nodes)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(skillTree.id, forKey: .id)
        try container.encode(skillTree.goalId, forKey: .goalId)
        try container.encode(skillTree.treeJson, forKey: .treeJson)
        try container.encode(skillTree.generatedBy, forKey: .generatedBy)
        try container.encode(skillTree.version, forKey: .version)
        try container.encode(skillTree.createdAt, forKey: .createdAt)
        try container.encode(skillTree.updatedAt, forKey: .updatedAt)
        try container.encode(nodes, forKey: .nodes)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case goalId = "goal_id"
        case treeJson = "tree_json"
        case generatedBy = "generated_by"
        case version
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case nodes
    }
}
