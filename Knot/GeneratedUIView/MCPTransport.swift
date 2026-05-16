//
//  MCPTransport.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/16.
//

import Foundation
import MCP
import System

func connectToMCPServer(input: String) async throws -> (StdioTransport, Process)
{
    let (command, args) = parseArguments(input)

    let process = Process()
    process.environment = ["PATH": "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"]
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [command] + args
//    process.executableURL = URL(fileURLWithPath: command)
//    process.arguments = args

    let inputPipe = Pipe()
    let outputPipe = Pipe()

    process.standardInput = inputPipe
    process.standardOutput = outputPipe

    try process.run()

    let transport = StdioTransport(
        input: FileDescriptor(
            rawValue: outputPipe.fileHandleForReading.fileDescriptor
        ),
        output: FileDescriptor(
            rawValue: inputPipe.fileHandleForWriting.fileDescriptor
        )
    )

    return (transport, process)
}

func parseArguments(_ input: String) -> (command: String, args: [String]) {
    // Split the input by spaces, ignoring spaces between double quotations
    let pattern = #""[^"]*"|'[^']*'|[^\s"']+"#
    let regex = try! NSRegularExpression(pattern: pattern)
    let matches = regex.matches(
        in: input,
        range: NSRange(input.startIndex..., in: input)
    )

    var tokens = matches.map {
        String(input[Range($0.range, in: input)!])
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
    }

    guard !tokens.isEmpty else { return ("", []) }
    let command = tokens.removeFirst()
    return (command, tokens)
}
