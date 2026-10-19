//
//  KnotThreadManager.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/14.
//

import Combine
import Foundation
internal import UniformTypeIdentifiers

@Observable class KnotThreadManager {
    static let shared = KnotThreadManager()

    var threads: [KnotThread] = []
    private var saveCancellable: AnyCancellable?
    private let saveSubject = PassthroughSubject<Void, Never>()

    private init() {
        // Load all the threads
        try? loadAll()

        print(threads)

        // Set up a debounce
        saveCancellable =
            saveSubject
            .debounce(for: .seconds(1.0), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                try? self?.saveAll()
            }
    }

    func requestSave() {
        saveSubject.send()
    }

    func saveAll() throws {
        do {
            let jsonData = try JSONEncoder().encode(threads)
            guard
                let targetDirectory = FileManager.default.urls(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask
                )
                .first?
                .appendingPathComponent("Knot", conformingTo: .directory)
            else {
                return
            }

            // Write the file to the path
            try FileManager.default.createDirectory(
                at: targetDirectory,
                withIntermediateDirectories: true
            )
            let targetPath = targetDirectory.appendingPathComponent(
                "threads",
                conformingTo: .json
            )
            try jsonData.write(to: targetPath, options: .atomic)
        } catch {
            print("Save Error:", error)
            throw error
        }
    }

    func loadAll() throws {
        do {
            guard
                let targetPath = FileManager.default.urls(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask
                )
                .first?
                .appendingPathComponent("Knot", conformingTo: .directory)
                .appendingPathComponent("threads", conformingTo: .json)
            else {
                return
            }

            // Load the threads from the path
            if FileManager.default.fileExists(atPath: targetPath.path) {
                let jsonData = try Data(contentsOf: targetPath)
                self.threads = try JSONDecoder().decode(
                    [KnotThread].self,
                    from: jsonData
                )
            }
        } catch {
            print("Load Error:", error)
            throw error
        }
    }
}
