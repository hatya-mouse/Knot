//
//  AddServerView.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/15.
//

import SwiftUI

struct AddServerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var command = ""
    var onSave: (MCPServerConfig) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Add MCP Server").font(.headline)

            Form {
                TextField("Server Name", text: $name)
                TextField("Command (e.g. npx)", text: $command)
            }

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Add") {
                    let config = MCPServerConfig(
                        name: name,
                        command: command
                    )
                    onSave(config)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 250)
    }
}
