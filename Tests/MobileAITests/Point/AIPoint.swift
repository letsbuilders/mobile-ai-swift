//
//  AIPoint.swift
//  AI
//
//  Created by Marzena on 17/09/2026.
//

import Foundation
import FoundationModels

@Generable
struct AIPoint: Codable {
    var response: String? = nil
    var runningTime: TimeInterval? = nil

    var subject: String? = nil
    var status: String? = nil
    var isImportant: Bool? = nil
    var dueDate: String? = nil
    var usersInCharge: [String]? = nil
    var workspace: String? = nil
    var category: String? = nil
    var location: String? = nil
    var room: String? = nil
    var customFields: [String]? = nil
}

enum AIPointProperty: CaseIterable {
    case subject
    case status
    case dueDate
    case isImportant
    case workspace
    case category
    case location
    case room
    case usersInCharge
    case customFields

    var name: String {
        switch self {
        case .subject: "Subject"
        case .status: "Status"
        case .dueDate: "DueDate"
        case .isImportant: "IsImportant"
        case .workspace: "Workspace"
        case .category: "Category"
        case .location: "Location"
        case .room: "Room"
        case .usersInCharge: "Users"
        case .customFields: "CustomFields"
        }
    }

    var evaluator: PropertyEvaluator<AIPoint> {
        switch self {
        case .subject: .accuracy(name: name, keyPath: \.subject)
        case .status: .equality(name: name, keyPath: \.status)
        case .dueDate: .equality(name: name, keyPath: \.dueDate)
        case .isImportant: .equality(name: name, keyPath: \.isImportant)
        case .workspace: .equality(name: name, keyPath: \.workspace)
        case .category: .equality(name: name, keyPath: \.category)
        case .location: .equality(name: name, keyPath: \.location)
        case .room: .equality(name: name, keyPath: \.room)
        case .usersInCharge: .completeness(name: name, keyPath: \.usersInCharge)
        case .customFields: .completeness(name: name, keyPath: \.customFields)
        }
    }

    static var allProperties: [AIPointProperty] {
        [.status, .dueDate, .isImportant, .workspace, .category, .location, .room]
    }
}
