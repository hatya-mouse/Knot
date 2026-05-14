//
//  GeminiResponse.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/13.
//

import Foundation

struct GeminiResponse: Codable {
    let candidates: [Candidate]

    struct Candidate: Codable {
        let content: Content
    }

    struct Content: Codable {
        let parts: [Part]
    }

    struct Part: Codable {
        let text: String
    }

    /// The first text in the response.
    var firstText: String? {
        candidates.first?.content.parts.first?.text
    }
}
