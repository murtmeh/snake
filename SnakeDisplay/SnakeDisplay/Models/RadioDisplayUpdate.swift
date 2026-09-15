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
