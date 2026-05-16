//
//  Thread.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/14.
//

import SwiftUI

@Observable class KnotThread: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String
    var components: [String: A2UIComponent]
    var states: [String: A2UIValue]
    var createdAt: Date = Date()

    // MARK: Codable Implementation

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case components
        case states
        case createdAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.components = try container.decode(
            [String: A2UIComponent].self,
            forKey: .components
        )
        self.states = try container.decode(
            [String: A2UIValue].self,
            forKey: .states
        )
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(components, forKey: .components)
        try container.encode(states, forKey: .states)
        try container.encode(createdAt, forKey: .createdAt)
    }

    // MARK: Hashable Implementation

    static func == (lhs: KnotThread, rhs: KnotThread) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: Class Methods

    init(
        title: String,
        components: [String: A2UIComponent],
        states: [String: A2UIValue]
    ) {
        self.title = title
        self.components = components
        self.states = states
    }

    func binding<T>(for path: String, defaultValue: T) -> Binding<T> {
        Binding(
            get: { self.states[path]?.tryInto() ?? defaultValue },
            set: {
                self.states[path] = A2UIValue.tryFrom(value: $0)
                KnotThreadManager.shared.requestSave()
            }
        )
    }

    func get<T>(for path: String, defaultValue: T) -> T {
        states[path]?.tryInto() ?? defaultValue
    }
}
