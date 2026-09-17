//
//  RadioFoodUpdate.swift
//  SnakeDisplay
//
//  Created by Måns Jäderlund on 2026-09-16.
//

/// A decoded snapshot of one microbit's food pixel, forwarded over radio and relayed to us over serial.
nonisolated struct RadioFoodUpdate: Hashable, Sendable {
    let serialNumber: Int32
    let position: GridPoint
}
