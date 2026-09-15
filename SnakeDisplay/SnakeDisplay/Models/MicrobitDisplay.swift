//
//  MicrobitDisplay.swift
//  SnakeDisplay
//
//  Created by Måns Jäderlund on 2026-09-15.
//

/// The latest known LED state for one microbit taking part in the game.
nonisolated struct MicrobitDisplay: Identifiable, Hashable, Sendable {
    var id: Int32 { serialNumber }
    let serialNumber: Int32
    var litPixels: [GridPoint: Double]
}
