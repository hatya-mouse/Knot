//
//  KnotViewModel.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/13.
//

import SwiftUI
import MCP
internal import Combine

@Observable
class KnotViewModel {
    /// The main MCP client.
    private var client = Client(name: "Knot", version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
    
    /// Array of tools to show on the UI.
    @Published var tools = [Tool]()
    /// Whether the client is connected.
    @Published var isConnected = false
    /// The last MCP result.
    @Published var lastResult = ""
    
    /// Connects to the stdio transport and fetches the tools.
    func connect() async {
        // Use the stdio transport
        let transport = StdioTransport()
        do {
            _ = try await client.connect(transport: transport)
            self.isConnected = true
            // Get the tools as soon as the client is connected
            let (tools, _) = try await client.listTools()
            self.tools = tools
        } catch {
            print("Connection Error: \(error)")
        }
    }
    
    /// Runs the tools.
    func runTool(name: String, args: [String: Value]) async {
        do {
            let (content, isError) = try await client.callTool(name: name, arguments: args)
            // Parse the results and show on the UI
            if let firstText = content.first(where: { if case .text = $0 { return true }; return false }) {
                if case .text(let text, _, _) = firstText {
                    self.lastResult = text
                }
            }
        } catch {
            print("Run Error: \(error)")
        }
    }
}
