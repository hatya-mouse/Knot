//
//  GeminiProvider.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/13.
//

import GoogleGenerativeAI

struct GeminiProvider: LLMProvider {
    let displayName = "Google Gemini"
    private let model: GenerativeModel

    init(apiKey: some StringProtocol) {
        self.model = GenerativeModel(name: "gemini-1.5-flash", apiKey: String(apiKey))
    }

    func generateResponse(prompt: String, systemPrompt: String?) async throws -> String {
        // システムプロンプトも含めてリクエストを構築するにゃ
        let response = try await model.generateContent(prompt)
        return response.text ?? ""
    }
}
