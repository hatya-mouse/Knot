//
//  SettingsView.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/15.
//

import SwiftUI

let openAIProviderKey = "com.hatya.Knot.openai_api_key"
let geminiProviderKey = "com.hatya.Knot.gemini_api_key"
let claudeProviderKey = "com.hatya.Knot.claude_api_key"

struct SettingsView: View {
    @State private var isShowingAddMCPServer: Bool = false

    @State private var openAIKey: String = ""
    @State private var geminiKey: String = ""
    @State private var claudeKey: String = ""

    @State private var openAISaved: Bool = false
    @State private var geminiSaved: Bool = false
    @State private var claudeSaved: Bool = false

    var body: some View {
        Form {
            // MARK: MCP Servers
            Section("MCP Servers") {
                ForEach(MCPServerManager.shared.configs) { config in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(config.name).font(.headline)
                            Text(config.command).font(.caption).foregroundColor(
                                .secondary
                            )
                        }
                        Spacer()
                        Button(role: .destructive) {
                            MCPServerManager.shared.removeConfig(config)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
                Button {
                    isShowingAddMCPServer = true
                } label: {
                    Label(
                        "Add MCP Server",
                        systemImage: "plus.rectangle.on.folder"
                    )
                }
            }

            // MARK: OpenAI
            providerSection(
                text: $openAIKey,
                isSaved: $openAISaved,
                provider: "OpenAI",
                providerKey: openAIProviderKey,
                systemIcon: "bolt",
            )

            // MARK: Google Gemini
            providerSection(
                text: $geminiKey,
                isSaved: $geminiSaved,
                provider: "Google Gemini",
                providerKey: geminiProviderKey,
                systemIcon: "sparkles.2",
            )

            // MARK: Anthropic Claude
            providerSection(
                text: $claudeKey,
                isSaved: $claudeSaved,
                provider: "Anthropic Claude",
                providerKey: claudeProviderKey,
                systemIcon: "brain",
            )
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 450)
        .onAppear(perform: checkAllKeys)
        .sheet(isPresented: $isShowingAddMCPServer) {
            AddServerView { newConfig in
                MCPServerManager.shared.addConfig(newConfig)
                isShowingAddMCPServer = false
            }
        }
    }

    @ViewBuilder
    private func providerSection(
        text: Binding<String>,
        isSaved: Binding<Bool>,
        provider: String,
        providerKey: String,
        systemIcon: String,
    ) -> some View {
        Section {
            SecureField("API Key", text: text)
                .onChange(of: text.wrappedValue) {
                    isSaved.wrappedValue = false
                }
            HStack {
                Button("Update Key") {
                    saveAPIKey(
                        providerKey: providerKey,
                        apiKey: text.wrappedValue
                    )
                    text.wrappedValue = ""
                }
                if isSaved.wrappedValue {
                    Label(
                        "Saved in Keychain",
                        systemImage: "checkmark.circle.fill"
                    )
                    .foregroundColor(.green)
                    .transition(
                        .asymmetric(
                            insertion: .scale.animation(.bouncy(duration: 0.3)),
                            removal: .identity
                        )
                    )
                }
            }
        } header: {
            Label(provider, systemImage: systemIcon)
                .font(.headline)
        }
    }

    // MARK: -- HELPER FUNCTIONS

    private func saveAPIKey(providerKey: String, apiKey: String) {
        guard !apiKey.isEmpty else { return }
        Task {
            KeychainHelper.save(key: providerKey, data: apiKey)
            checkAllKeys()
        }
    }

    private func checkAllKeys() {
        geminiSaved = KeychainHelper.exists(key: geminiProviderKey)
        openAISaved = KeychainHelper.exists(key: openAIProviderKey)
        claudeSaved = KeychainHelper.exists(key: claudeProviderKey)
    }
}
