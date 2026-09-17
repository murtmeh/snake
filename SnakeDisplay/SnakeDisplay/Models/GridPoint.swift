//
//  GridPoint.swift
//  SnakeDisplay
//
//  Created by Måns Jäderlund on 2026-09-15.
//

/// A lit-pixel coordinate on a 5x5 microbit LED display, with (0, 0) at the top left.
nonisolated struct GridPoint: Hashable, Sendable {
    let column: Int
    let row: Int
}
