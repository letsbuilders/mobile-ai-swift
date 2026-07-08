//
//  Log.swift
//  AproplanAI
//
//  Created by Marzena on 07/07/2026.
//

import Foundation

protocol Loggable {}

extension Loggable {
    func checkTime<T>(_ message: String,
                      isolation: isolated (any Actor)? = #isolation,
                      _ block: () async throws -> T) async rethrows -> T {
        let start = Date()

        let result = try await block()

        info(message + " finished in \(Date.now.timeIntervalSince(start)) sec")
        return result
    }

    func info(_ message: String) {
        Log.info(Self.self, message)
    }

    func error(_ message: String) {
        Log.error(Self.self, message)
    }

    func error(_ error: Error, in message: String? = nil) {
        if let message {
            Log.error(Self.self, "Error in \(message): \(error.localizedDescription)")
        } else {
            Log.error(Self.self, "Error: \(error.localizedDescription)")
        }
    }

    func `throw`(_ error: Error) throws {
        self.error(error)
        throw error
    }
}

struct Log {
    static func info(_ source: Any.Type, _ message: String) {
        print("T\(threadNumber()):INFO: \(source): \(message)")
    }

    static func error(_ source: Any.Type, _ message: String) {
        print("T\(threadNumber()):ERROR: \(source): \(message)")
    }

    private static func threadNumber() -> Int {
        let description = Thread.current.description
        guard let range = description.range(of: #"number = (\d+)"#, options: .regularExpression) else {
            return 0
        }
        let match = description[range]
        return Int(match.dropFirst("number = ".count)) ?? 0
    }
}
