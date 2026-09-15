//
//  RadioDisplayUpdate.swift
//  SnakeDisplay
//
//  Created by Måns Jäderlund on 2026-09-15.
//

/// A decoded snapshot of one microbit's LED display, forwarded over radio and relayed to us over serial.
nonisolated struct RadioDisplayUpdate: Hashable, Sendable {
    let serialNumber: Int32
    let litPixels: [GridPoint: Double]
}

nonisolated enum RadioMessageParser {
    /// Only radio kind 1 (the snake game's broadcast) is currently produced; anything else is ignored.
    private static let supportedRadioKind = 1

    static func parse(_ line: String) -> RadioDisplayUpdate? {
        let fields = line.split(separator: ";", omittingEmptySubsequences: true)
        guard let radioKind = fields.first.flatMap({ Int($0) }), radioKind == supportedRadioKind else {
            return nil
        }
        guard fields.count >= 2, let serialNumber = Int32(fields[1]) else {
            return nil
        }

        var litPixels: [GridPoint: Double] = [:]
        for field in fields.dropFirst(2) {
            let components = field.split(separator: ",")
            guard components.count == 3,
                  let column = Int(components[0]),
                  let row = Int(components[1]),
                  let brightness = Double(components[2]) else {
                return nil
            }
            litPixels[GridPoint(column: column, row: row)] = brightness
        }

        return RadioDisplayUpdate(serialNumber: serialNumber, litPixels: litPixels)
    }
}
