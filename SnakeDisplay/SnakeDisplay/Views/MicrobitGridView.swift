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
    /// Matches the microbit's `LedSpriteProperty.Blink` interval for the food sprite.
    private static let foodBlinkInterval: TimeInterval = 0.25

    var body: some View {
        VStack(spacing: 8) {
            Text("Microbit \(display.serialNumber)")
                .font(.headline)

            HStack(spacing: 8) {
                ButtonIndicator(label: "A", isFlashing: isFlashing(.buttonA))
                grid
                ButtonIndicator(label: "B", isFlashing: isFlashing(.buttonB))
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var grid: some View {
        ZStack {
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
                                .overlay {
                                    if isFood(column: column, row: row) {
                                        foodPixel
                                    }
                                }
                                .frame(width: 24, height: 24)
                        }
                    }
                }
            }

            if display.isDead {
                Image(systemName: "xmark.octagon.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .foregroundStyle(.red)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Microbit \(display.serialNumber) display")
        .accessibilityValue(display.isDead ? "Player eliminated" : "\(display.litPixels.count) of 25 pixels lit")
    }

    /// The pixel's brightness (0-255) scaled to a 0...1 fill opacity, unlit cells are 0.
    private func brightnessFraction(column: Int, row: Int) -> Double {
        let brightness = display.litPixels[GridPoint(column: column, row: row)] ?? 0
        return min(max(brightness / 255, 0), 1)
    }

    /// Blinks locally, since the microbit only reports the food's position when it moves
    /// rather than on every blink cycle. Driven by the clock rather than an animation, so it
    /// blinks no matter when the first food update arrives.
    private var foodPixel: some View {
        TimelineView(.periodic(from: .now, by: Self.foodBlinkInterval)) { context in
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.red)
                .opacity(Self.isFoodBlinkVisible(at: context.date) ? 1 : 0)
        }
    }

    private static func isFoodBlinkVisible(at date: Date) -> Bool {
        Int(date.timeIntervalSinceReferenceDate / foodBlinkInterval) % 2 == 0
    }

    private func isFood(column: Int, row: Int) -> Bool {
        display.foodPixel == GridPoint(column: column, row: row)
    }

    private func isFlashing(_ button: MicrobitButton) -> Bool {
        display.pressedButton == button || display.pressedButton == .bothButtons
    }
}

private struct ButtonIndicator: View {
    let label: String
    let isFlashing: Bool

    var body: some View {
        Text(label)
            .font(.caption.bold())
            .foregroundStyle(isFlashing ? Color.black : Color.secondary)
            .frame(width: 22, height: 22)
            .background(Circle().fill(isFlashing ? Color.yellow : Color.secondary.opacity(0.15)))
            .animation(.easeOut(duration: 0.15), value: isFlashing)
            .accessibilityLabel("Button \(label)")
            .accessibilityValue(isFlashing ? "Pressed" : "Idle")
    }
}

#Preview("Alive") {
    MicrobitGridView(
        display: MicrobitDisplay(
            serialNumber: -97_649_137,
            litPixels: [
                GridPoint(column: 4, row: 2): 255,
                GridPoint(column: 3, row: 2): 191.25,
                GridPoint(column: 2, row: 2): 127.5,
                GridPoint(column: 1, row: 2): 63.75
            ],
            pressedButton: .buttonA,
            foodPixel: GridPoint(column: 1, row: 3)
        )
    )
    .padding()
}

#Preview("Dead") {
    MicrobitGridView(
        display: MicrobitDisplay(
            serialNumber: -97_649_137,
            litPixels: [:],
            pressedButton: nil,
            isDead: true
        )
    )
    .padding()
}
