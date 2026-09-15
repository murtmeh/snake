//
//  RadioMessage.swift
//  SnakeDisplay
//
//  Created by Måns Jäderlund on 2026-09-15.
//

nonisolated enum MicrobitButton: String, Hashable, Sendable {
    case buttonA = "A"
    case buttonB = "B"
    case bothButtons = "A+B"
}

nonisolated struct ButtonPressEvent: Hashable, Sendable {
    let serialNumber: Int32
    let button: MicrobitButton
}

nonisolated enum RadioMessage: Hashable, Sendable {
    case displayUpdate(RadioDisplayUpdate)
    case buttonPress(ButtonPressEvent)
}

/// Parses lines relayed over serial:
/// - `1;-976498137;4,2,255;3,2,191.25;...;`: radio kind, serial number, lit pixels (x, y, brightness)
/// - `2;-976498137;B;`: radio kind, serial number, the button pressed (`A`, `B`, or `A+B`)
nonisolated enum RadioMessageParser {
    private static let displayUpdateRadioKind = 1
    private static let buttonPressRadioKind = 2

    static func parse(_ line: String) -> RadioMessage? {
        let fields = line.split(separator: ";", omittingEmptySubsequences: true)
        guard let radioKind = fields.first.flatMap({ Int($0) }) else {
            return nil
        }

        switch radioKind {
        case displayUpdateRadioKind:
            return parseDisplayUpdate(fields).map(RadioMessage.displayUpdate)
        case buttonPressRadioKind:
            return parseButtonPress(fields).map(RadioMessage.buttonPress)
        default:
            return nil
        }
    }

    private static func parseDisplayUpdate(_ fields: [Substring]) -> RadioDisplayUpdate? {
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

    private static func parseButtonPress(_ fields: [Substring]) -> ButtonPressEvent? {
        guard fields.count == 3,
              let serialNumber = Int32(fields[1]),
              let button = MicrobitButton(rawValue: String(fields[2])) else {
            return nil
        }
        return ButtonPressEvent(serialNumber: serialNumber, button: button)
    }
}
