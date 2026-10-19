//
//  GeneratedUI.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/14.
//

import SwiftUI

struct GeneratedUI: View {
    @State var thread: KnotThread
    @State private var communicator: MCPAICommunicator

    @State var promptFieldText: String = ""
    @FocusState var promptFieldFocused: Bool

    // State variables for send prompt animation
    @State private var animatedText = ""
    @State private var isAnimating = false
    @State private var textOffset: CGFloat = 0
    @State private var textOpacity: Double = 0.0

    // Component hover tooltip
    @State private var hoverTooltip: String?

    init(thread: KnotThread) {
        self.thread = thread
        self.communicator = MCPAICommunicator(thread: thread)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                ScrollView(.vertical, showsIndicators: false) {
                    KnotRenderer(
                        components: communicator.thread.components,
                        thread: thread,
                        rootID: "root",
                        onComponentHover: { tooltip in
                            withAnimation(.easeOut(duration: 0.1)) {
                                self.hoverTooltip = tooltip
                            }
                        },
                        communicator: communicator
                    )
                    .padding()
                }

                if let tooltip = hoverTooltip {
                    Text(tooltip)
                        .font(
                            .system(
                                size: 11,
                                weight: .medium,
                                design: .monospaced
                            )
                        )
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .glassEffect()
                        .transition(.opacity)
                        .padding()
                }
            }

            HStack {
                TextField(
                    "Generate UI",
                    text: $promptFieldText,
                    axis: .vertical
                )
                .font(.system(size: 14))
                .lineLimit(1...5)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .focused($promptFieldFocused)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    Color(.separatorColor),
                                    lineWidth: 1
                                )
                        )
                )
                .overlay(
                    Group {
                        if isAnimating {
                            Text(animatedText)
                                .font(.system(size: 14))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .offset(y: textOffset)
                                .opacity(textOpacity)
                        }
                    },
                    alignment: .bottomLeading
                )
                .onSubmit(handleAnimateSubmit)

                Button(role: .confirm) {
                    handleAnimateSubmit()
                } label: {
                    Image(systemName: "paperplane")
                        .font(.system(size: 14))
                        .padding(.vertical, 4)
                }
                .keyboardShortcut(.return)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(minWidth: 500, minHeight: 400)
    }

    private func handleAnimateSubmit() {
        let trimmed = promptFieldText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmed.isEmpty else { return }

        animatedText = trimmed

        textOffset = 0
        textOpacity = 1.0
        isAnimating = true

        promptFieldText = ""

        submitPrompt()

        withAnimation(.easeIn.speed(2.0)) {
            textOffset = -50
            textOpacity = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isAnimating = false
        }
    }

    func submitPrompt() {
        let userPrompt = promptFieldText
        Task {
            await communicator.requestUI(userPrompt: userPrompt)
        }
        promptFieldText = ""
    }
}
