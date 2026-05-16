//
//  LLMError.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/13.
//

class LLMError: Error {
    let localizedDescription: String

    init(_ description: String) {
        self.localizedDescription = description
    }
}
