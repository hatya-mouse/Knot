//
//  MCPServerManager.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/16.
//

import Foundation

/// Saves and loads the MCP server configs using UserDefaults.
@Observable class MCPServerManager {
    static let shared = MCPServerManager()

    var configs: [MCPServerConfig] = [] {
        didSet {
            // Save the config when changed
            save()
        }
    }

    private init() {
        load()
    }

    func addConfig(_ config: MCPServerConfig) {
        configs.append(config)
    }

    func removeConfig(_ config: MCPServerConfig) {
        if let index = configs.firstIndex(where: { $0.id == config.id }) {
            configs.remove(at: index)
        }
    }

    func save() {
        if let encoded = try? JSONEncoder().encode(configs) {
            UserDefaults.standard.set(encoded, forKey: "mcp_server_configs")
        }
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: "mcp_server_configs"),
            let decoded = try? JSONDecoder().decode(
                [MCPServerConfig].self,
                from: data
            )
        {
            self.configs = decoded
        }
    }
}
