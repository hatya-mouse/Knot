//
//  MCPServerConfig.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/15.
//

import Foundation

struct MCPServerConfig: Codable, Identifiable {
    var id = UUID()
    var name: String
    var command: String
}
