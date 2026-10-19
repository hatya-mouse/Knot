//
//  A2UIDataStore.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/13.
//

import MCP
import SwiftUI

enum ValueOrBinding: Codable, Hashable {
    case literal(A2UIValue)
    case binding(String)

    struct BindingPath: Codable {
        let path: String
    }

    init(from decoder: Decoder) throws {
        // 1. Try parsing as a data binding
        if let pathObj = try? BindingPath(from: decoder) {
            self = .binding(pathObj.path)
        }

        // 2. Then parse as a literal value
        else if let literalVal = try? A2UIValue(from: decoder) {
            self = .literal(literalVal)
        } else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid value format"
                )
            )
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .literal(let value):
            try container.encode(value)
        case .binding(let path):
            try container.encode(["path": path])
        }
    }
}

enum A2UIValue: Codable, Hashable {
    case string(String)
    case number(Double)
    case bool(Bool)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let d = try? container.decode(Double.self) {
            self = .number(d)
        } else if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "A2UIValue: Unsupported type"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .number(let d): try container.encode(d)
        case .bool(let b): try container.encode(b)
        }
    }

    /// Tries to cast the A2UIValue into the expected type.
    func tryInto<T>() -> T? {
        switch self {
        case .string(let s): return s as? T
        case .number(let d):
            if T.self == Double.self { return d as? T }
            if T.self == Float.self { return Float(d) as? T }
            if T.self == Int.self { return Int(d) as? T }
            if T.self == String.self { return String(d) as? T }
            return nil
        case .bool(let b):
            if T.self == Bool.self { return b as? T }
            if T.self == String.self { return (b ? "true" : "false") as? T }
            return nil
        }
    }

    /// Tries to create a new A2UIValue from the given raw value.
    static func tryFrom<T>(value: T) -> A2UIValue? {
        switch value {
        case let value as String: .string(value)
        case let value as Int: .number(Double(value))
        case let value as Float: .number(Double(value))
        case let value as Double: .number(Double(value))
        case let value as Bool: .bool(value)
        default: nil
        }
    }

    /// Converts the value to MCP Value.
    func toMCPValue() -> Value {
        switch self {
        case .string(let s): .string(s)
        case .number(let d): .double(d)
        case .bool(let b): .bool(b)
        }
    }
}
