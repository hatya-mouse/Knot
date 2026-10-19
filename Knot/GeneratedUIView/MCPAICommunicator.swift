//
//  MCPAICommunicator.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/13.
//

import Combine
import MCP
import SwiftUI

@Observable class MCPAICommunicator {
    /// The main MCP client.
    private var client = Client(
        name: "Knot",
        version: Bundle.main.infoDictionary?["CFBundleShortVersionString"]
            as? String ?? ""
    )
    /// The LLM provider to generate the UI.
    var provider: LLMProvider? {
        GeminiProvider()
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
    /// Currently active MCP server processes.
    var serverProcesses: [Process] = []

    /// Initializes a new instance of MCPAICommunicator from a thread.
    init(thread: KnotThread) {
        self.thread = thread

        Task {
            await self.connectAll()
        }
    }

    /// Request the UI to the LLM provider.
    func requestUI(userPrompt: String) async {
        guard let provider = provider else { return }

        isGenerating = true
        let systemPrompt = generateSystemPrompt()

        do {
            let result = try await provider.generateResponse(
                prompt: userPrompt,
                systemPrompt: systemPrompt
            )

            let components = try JSONDecoder().decode(
                [A2UIComponent].self,
                from: result
            )

            await MainActor.run {
                // Update the UI components
                self.thread.components.removeAll()
                for comp in components {
                    self.thread.components[comp.id] = comp
                }

                // Initialize the states
                self.thread.initStates()
            }
        } catch let error {
            print("Error: \(error.localizedDescription)")
            self.thread.components = [
                "root": A2UIComponent(
                    id: "root",
                    component: "Card",
                    label: nil,
                    text: nil,
                    value: nil,
                    variant: nil,
                    min: nil,
                    max: nil,
                    children: nil,
                    child: "message"
                ),
                "message": A2UIComponent(
                    id: "message",
                    component: "Text",
                    label: nil,
                    text: .literal(
                        .string("Error: \(error.localizedDescription)")
                    ),
                    value: nil,
                    variant: nil,
                    min: nil,
                    max: nil,
                    children: nil,
                    child: nil
                ),
            ]
        }
        isGenerating = false
    }

    func prefixSchema(_ schema: [String: Value], prefix: String) -> [String:
        Value]
    {
        var prefixed: [String: Value] = [:]
        for (argName, schema) in schema {
            let prefixedName = "\(prefix)\(argName)"
            prefixed[prefixedName] = schema
        }
        return prefixed
    }

    func generateSystemPrompt() -> String {
        let toolsContext = tools.map { tool in
            // Add the tool name as the prefix
            var prefixedInputs: [String: Value] = [:]
            var prefixedOutputs: [String: Value] = [:]
            if let inputs = tool.inputSchema.objectValue {
                prefixedInputs = prefixSchema(
                    inputs,
                    prefix: "\(tool.name)_input_"
                )
            }
            if let outputs = tool.outputSchema?.objectValue {
                prefixedOutputs = prefixSchema(
                    outputs,
                    prefix: "\(tool.name)_output_"
                )
            } else {
                // Add an output named "value" if no output is specified.
                prefixedOutputs = prefixSchema(
                    ["value": .null],
                    prefix: "\(tool.name)_output_"
                )
            }

            return
                "Tool: \(tool.name), Description: \(tool.description ?? ""), Inputs: \(prefixedInputs), Outputs: \(prefixedOutputs)"
        }.joined(separator: "\n")

        return """
            1. Generate a UI written in JSON with the specific A2UI format based on the user's prompt.
            2. The root UI must be either Card, Column or Row, and must be named "root".
            3. For Buttons, use the exact same name as the target MCP tool name for its component ID.

            Strict Data Binding Rules (CRITICAL):
            4. For interactive input components (Slider, CheckBox, TextField), you MUST use data binding for their "value" property.
               The binding path string MUST match the exact prefixed input key provided in the [Available Tools] section (e.g., "toolName_input_argumentName").
               Example: "value": { "path": "get-sum_input_a" }

            5. For output display components (Text), you MUST bind their text content to the corresponding output key using data binding.
               The binding path string MUST match the exact prefixed output key provided in the [Available Tools] section (e.g., "toolName_output_resultKey").
               Example: "text": { "path": "get-sum_output_value" }

            Specific Constraints:
            - Column and Row must have "children" property. Do not use "child" property for them, even if there is only one child.
            - Card must have "child" property.
            - Button has to have "child" property which specifies the ID of its label content component, not "text" or "label" directly on the button.
            - Never use literal values for interactive components' value property, or the user will not be able to interact with it.
            - You can create any data binding dynamically by just specifying the path string as guided above. It automatically registers in the app state.

            [Current UI Status]
            \(thread.components)

            [Available Tools Specification]
            \(toolsContext)
            """
    }

    /// Connects to the stdio transport and fetches the tools.
    func connectAll() async {
        // Get all the servers available
        self.tools.removeAll()
        self.serverProcesses.removeAll()
        for config in MCPServerManager.shared.configs {
            await connectServer(command: config.command)
        }
    }

    private func connectServer(command: String) async {
        do {
            // Launch the MCP server and get the transport
            let (transport, process) = try await connectToMCPServer(
                input: command
            )
            self.serverProcesses.append(process)
            // Try to connect to the transport
            _ = try await client.connect(transport: transport)
            self.isConnected = true

            // Get the tools as soon as the client is connected
            let (tools, _) = try await client.listTools()
            self.tools.append(contentsOf: tools)
        } catch {
            print("Connection Error: \(error)")
        }
    }

    func triggerMCPTool(_ toolName: String) async {
        var resolvedInputs: [String: Value] = [:]

        // Get the tool properties to get the desired type of inputs
        guard let tool = tools.first(where: { $0.name == toolName }) else {
            return
        }
        let properties = tool.inputSchema.objectValue?["properties"]?
            .objectValue

        for (stateID, value) in thread.states {
            // Check if the state ID begins with the tool name and _input_ prefix
            if stateID.hasPrefix("\(toolName)_input_") {
                // Remove the prefix and get the actual argument name
                let originalKey = String(stateID.dropFirst(toolName.count + 7))
                let rawValue = value.toMCPValue()

                let argSchema = properties?[originalKey]?.objectValue
                let expectedType = argSchema?["type"]?.stringValue

                // Convert to the desired type
                if let strValue = rawValue.stringValue {
                    if expectedType == "number" {
                        if let doubleVal = Double(strValue) {
                            resolvedInputs[originalKey] = .double(doubleVal)
                            continue
                        }
                    } else if expectedType == "integer" {
                        if let intVal = Int(strValue) {
                            resolvedInputs[originalKey] = .int(intVal)
                            continue
                        }
                    }
                }

                resolvedInputs[originalKey] = rawValue
            }
        }

        // Run the tool with the resolved inputs
        await runTool(toolName, with: resolvedInputs)
    }

    /// Runs the tools.
    func runTool(_ toolName: String, with inputs: [String: Value]) async {
        do {
            let (content, _) = try await client.callTool(
                name: toolName,
                arguments: inputs
            )
            let parsedContent = content.toDictionary()

            await MainActor.run {
                // Parse the results and show on the UI
                for stateID in thread.states.keys {
                    // Check if the state ID begins with the tool name and _output_ prefix
                    if stateID.hasPrefix("\(toolName)_output_") {
                        // Remove the prefix and get the actual argument name
                        let originalKey = String(
                            stateID.dropFirst(toolName.count + 8)
                        )
                        // Get the value from the states
                        if let newValue = A2UIValue.tryFrom(
                            value: parsedContent[originalKey]
                        ) {
                            thread.states.updateValue(newValue, forKey: stateID)
                        }
                    }
                }
            }
        } catch {
            print("Run Error: \(error)")
        }
    }
}
