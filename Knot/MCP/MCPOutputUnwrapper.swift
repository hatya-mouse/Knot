//
//  MCPOutputUnwrapper.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/16.
//

import Foundation
import MCP

extension [Tool.Content] {
    /// Parses the content as a JSON data, or extracts the text data from it.
    func toDictionary() -> [String: Any] {
        let fullText = self.compactMap { content -> String? in
            if case .text(let text, _, _) = content {
                return text
            }
            return nil
        }.joined()
        
        // If the content is a JSON data, parse it
        if let data = fullText.data(using: .utf8),
           let jsonDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return jsonDict
        }
        
        // If the text is not a structured JSON data, return the full text
        return ["value": fullText]
    }
}
