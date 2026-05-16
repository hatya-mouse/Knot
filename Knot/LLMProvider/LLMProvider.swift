//
//  LLMProvider.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/13.
//

import Foundation

protocol LLMProvider {
    /// The name of the LLM provider for displaying purpose.
    var displayName: String { get }
    /// Generate the response using the user prompt and the system prompt.
    func generateResponse(prompt: String, systemPrompt: String?) async throws
        -> Data
}
