//
//  RadioMessageParserTests.swift
//  SnakeDisplayTests
//
//  Created by Måns Jäderlund on 2026-09-15.
//

import Testing
@testable import SnakeDisplay

struct RadioMessageParserTests {
    @Test func parsesLitPixelsWithTheirBrightness() {
        let message = RadioMessageParser.parse("1;-976498137;4,2,255;3,2,191.25;2,2,127.5;1,2,63.75;")

        guard case let .displayUpdate(update) = message else {
            Issue.record("Expected a display update")
            return
        }
        #expect(update.serialNumber == -976_498_137)
        #expect(update.litPixels == [
            GridPoint(column: 4, row: 2): 255,
            GridPoint(column: 3, row: 2): 191.25,
            GridPoint(column: 2, row: 2): 127.5,
            GridPoint(column: 1, row: 2): 63.75
        ])
    }

    @Test func parsesAnEmptyDisplay() {
        let message = RadioMessageParser.parse("1;-976498137;")

        guard case let .displayUpdate(update) = message else {
            Issue.record("Expected a display update")
            return
        }
        #expect(update.serialNumber == -976_498_137)
        #expect(update.litPixels == [:])
    }

    @Test func parsesEachButtonPress() {
        for (rawButton, expectedButton) in [("A", MicrobitButton.buttonA), ("B", .buttonB), ("A+B", .bothButtons)] {
            let message = RadioMessageParser.parse("2;-976498137;\(rawButton);")

            guard case let .buttonPress(event) = message else {
                Issue.record("Expected a button press for \(rawButton)")
                continue
            }
            #expect(event.serialNumber == -976_498_137)
            #expect(event.button == expectedButton)
        }
    }

    @Test func rejectsAnUnknownButton() {
        #expect(RadioMessageParser.parse("2;-976498137;C;") == nil)
    }

    @Test func parsesADeathEvent() {
        let message = RadioMessageParser.parse("5;-976498137;death;")

        guard case let .death(event) = message else {
            Issue.record("Expected a death event")
            return
        }
        #expect(event.serialNumber == -976_498_137)
    }

    @Test func rejectsAMalformedDeathEvent() {
        #expect(RadioMessageParser.parse("5;-976498137;dead;") == nil)
        #expect(RadioMessageParser.parse("5;-976498137;") == nil)
    }

    @Test func ignoresUnsupportedRadioKinds() {
        #expect(RadioMessageParser.parse("0;-976498137;4,2,255;") == nil)
        #expect(RadioMessageParser.parse("3;-976498137;4,2,255;") == nil)
    }

    @Test func rejectsAMissingSerialNumber() {
        #expect(RadioMessageParser.parse("1;") == nil)
        #expect(RadioMessageParser.parse("1") == nil)
        #expect(RadioMessageParser.parse("2;") == nil)
    }

    @Test func rejectsAMalformedCoordinate() {
        #expect(RadioMessageParser.parse("1;-976498137;4,2,255;garbage;") == nil)
        #expect(RadioMessageParser.parse("1;-976498137;4,2;") == nil)
        #expect(RadioMessageParser.parse("1;-976498137;4;") == nil)
    }

    @Test func rejectsGarbledInput() {
        #expect(RadioMessageParser.parse("") == nil)
        #expect(RadioMessageParser.parse(";;;") == nil)
    }
}
