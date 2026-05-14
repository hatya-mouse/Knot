//
//  GeneratedUIView.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/14.
//

import SwiftUI

struct GeneratedUI: View {
    @State var thread: KnotThread
    @State private var viewModel: KnotViewModel

    init(thread: KnotThread) {
        self.thread = thread
        self.viewModel = KnotViewModel(thread: thread)
    }

    var body: some View {
        VStack {
            Text(thread.title)

            Section("Settings") {
                SecureField("Gemini API Key", text: $viewModel.apiKey)
            }

            Section("AI Interaction") {
                Button(action: {
                    Task { await viewModel.requestUI() }
                }) {
                    if viewModel.isGenerating {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Generate UI")
                    }
                }
                .disabled(viewModel.apiKey.isEmpty || viewModel.isGenerating)
            }

            KnotRenderer(components: viewModel.thread.components, thread: thread, rootID: "root")
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
}
