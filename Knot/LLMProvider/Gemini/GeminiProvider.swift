//
//  GeminiProvider.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/13.
//

import Foundation

struct GeminiProvider: LLMProvider {
    let displayName = "Google Gemini"

    func generateResponse(prompt: String, systemPrompt: String?) async throws
        -> Data
    {
        let apiKey = KeychainHelper.load(key: geminiProviderKey)
        let url = URL(
            string:
                "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent"
        )!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let a2uiSchema: [String: Any] = [
            "type": "array",
            "items": [
                "type": "object",
                "properties": [
                    "id": ["type": "string"],
                    "component": [
                        "type": "string",
                        "enum": [
                            "Row", "Column", "List", "Text", "Divider",
                            "Button", "TextField", "CheckBox", "Slider", "Card",
                        ],
                    ],
                    "text": [
                        "type": "object",
                        "anyOf": [
                            [
                                "type": "object",
                                "properties": ["path": ["type": "string"]],
                            ],
                            ["type": "string"],
                        ],
                    ],
                    "label": ["type": "string"],
                    "value": [
                        "type": "object",
                        "anyOf": [
                            [
                                "type": "object",
                                "properties": ["path": ["type": "string"]],
                            ],
                            ["type": "string"],
                        ],
                    ],
                    "variant": [
                        "type": "string",
                        "enum": ["h1", "h2", "h3", "h4", "h5", "caption", "body"],
                    ],
                    "min": ["type": "number"],
                    "max": ["type": "number"],
                    "children": [
                        "type": "array",
                        "items": ["type": "string"],
                    ],
                    "child": ["type": "string"],
                ],
                "required": ["id", "component"],
            ],
        ]

        var body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": a2uiSchema,
            ],
        ]

        if let systemPrompt = systemPrompt {
            body["system_instruction"] = ["parts": [["text": systemPrompt]]]
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        if let dataString = String(data: data, encoding: .utf8) {
            print(dataString)
        }

        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        if let jsonString = decoded.firstText,
            let jsonData = jsonString.data(using: .utf8)
        {
            return jsonData
        } else {
            throw LLMError("Unable to parse Gemini response")
        }
    }
}
