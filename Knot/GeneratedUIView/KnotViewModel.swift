//
//  KnotViewModel.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/13.
//

import SwiftUI
import MCP
import Combine

@Observable final class KnotViewModel {
    /// The main MCP client.
    private var client = Client(name: "Knot", version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
    /// The LLM provider to generate the UI.
    var provider: LLMProvider? {
        GeminiProvider(apiKey: apiKey)
    }

    /// Array of tools to show on the UI.
    var tools = [Tool]()
    /// Whether the client is connected.
    var isConnected: Bool = false
    /// The last MCP result.
    var lastResult: String = ""
    /// The API key for Gemini API.
    var apiKey: String = ""
    /// Whether the model is currently generating the output.
    var isGenerating: Bool = false
    /// The generated A2UI components.
    var thread: KnotThread

    /// Initializes a new instance of KnotViewModel from a thread.
    init(thread: KnotThread) {
        self.thread = thread
    }

    /// Request the UI to the LLM provider.
    func requestUI() async {
        guard let provider = provider else { return }

        isGenerating = true
        let systemPrompt = "MCPツール定義を解析し、A2UI形式のJSONのみを出力してにゃ。IDはMCPの引数名と一致させること😼。最上位は必ずColumn, Row, Cardのいずれかとし、IDは \"root\" とすること。"
        let userPrompt = "Tool Name: set_volume, Arguments: level (number, 0-100)"

        do {
//            let result = try await provider.generateResponse(prompt: userPrompt, systemPrompt: systemPrompt)
            let dummyString = """
                [
                  {
                    "id": "root",
                    "component": "Card",
                    "children": ["main-vstack"]
                  },
                  {
                    "id": "main-vstack",
                    "component": "Column",
                    "children": ["header-text", "divider-1", "user-section", "settings-section"]
                  },
                  {
                    "id": "header-text",
                    "component": "Text",
                    "text": "Interactive Data Sync Test",
                    "variant": "h2"
                  },
                  {
                    "id": "divider-1",
                    "component": "Divider"
                  },
                  {
                    "id": "user-section",
                    "component": "Row",
                    "children": ["user-icon", "user-display-name"]
                  },
                  {
                    "id": "user-icon",
                    "component": "Text",
                    "text": "👤"
                  },
                  {
                    "id": "user-display-name",
                    "component": "Text",
                    "text": { "path": "/user/displayName" } 
                  },
                  {
                    "id": "settings-section",
                    "component": "Column",
                    "children": ["vol-label", "vol-slider", "status-field", "status-text"]
                  },
                  {
                    "id": "vol-label",
                    "component": "Text",
                    "text": "Adjust Master Volume"
                  },
                  {
                    "id": "vol-slider",
                    "component": "Slider",
                    "label": "Master Volume",
                    "value": { "path": "/settings/volume" },
                    "min": 0,
                    "max": 100
                  },
                  {
                    "id": "status-field",
                    "component": "TextField",
                    "label": "Status Text",
                    "value": { "path": "/system/statusMessage" }
                  },
                  {
                    "id": "status-text",
                    "component": "Text",
                    "text": { "path": "/system/statusMessage" }
                  }
                ]
                """
            let result = dummyString.data(using: .utf8) ?? Data()

            let components = try JSONDecoder().decode([A2UIComponent].self, from: result)

            self.thread.components.removeAll()
            for comp in components {
                self.thread.components.updateValue(comp, forKey: comp.id)
            }
        } catch let error {
            print("Error: \(error.localizedDescription)")
            self.thread.components = [
                "root": A2UIComponent(id: "root", component: "Card", label: nil, text: nil, value: nil, variant: nil, min: nil, max: nil, children: ["message"], child: nil),
                "message": A2UIComponent(id: "message", component: "Text", label: nil, text: .literal(.string("Error: \(error.localizedDescription)")), value: nil, variant: nil, min: nil, max: nil, children: nil, child: nil)
            ]
        }
        isGenerating = false
    }

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
            let (content, _) = try await client.callTool(name: name, arguments: args)
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
