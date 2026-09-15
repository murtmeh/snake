//
//  MicrobitGridView.swift
//  SnakeDisplay
//
//  Created by Måns Jäderlund on 2026-09-15.
//

import SwiftUI

/// Renders one microbit's 5x5 LED display.
struct MicrobitGridView: View {
    let display: MicrobitDisplay

    private static let gridRange = 0..<5

    var body: some View {
        VStack(spacing: 8) {
            Text("Microbit \(display.serialNumber)")
                .font(.headline)

            Grid(horizontalSpacing: 4, verticalSpacing: 4) {
                ForEach(Self.gridRange, id: \.self) { row in
                    GridRow {
                        ForEach(Self.gridRange, id: \.self) { column in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.secondary.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.orange.opacity(brightnessFraction(column: column, row: row)))
                                )
                                .frame(width: 24, height: 24)
                        }
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Microbit \(display.serialNumber) display")
            .accessibilityValue("\(display.litPixels.count) of 25 pixels lit")
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    /// The pixel's brightness (0-255) scaled to a 0...1 fill opacity, unlit cells are 0.
    private func brightnessFraction(column: Int, row: Int) -> Double {
        let brightness = display.litPixels[GridPoint(column: column, row: row)] ?? 0
        return min(max(brightness / 255, 0), 1)
    }
}

#Preview {
    MicrobitGridView(
        display: MicrobitDisplay(
            serialNumber: -97_649_137,
            litPixels: [
                GridPoint(column: 4, row: 2): 255,
                GridPoint(column: 3, row: 2): 191.25,
                GridPoint(column: 2, row: 2): 127.5,
                GridPoint(column: 1, row: 2): 63.75
            ]
        )
    )
    .padding()
}
