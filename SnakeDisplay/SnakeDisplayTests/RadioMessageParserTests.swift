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
        let update = RadioMessageParser.parse("1;-976498137;4,2,255;3,2,191.25;2,2,127.5;1,2,63.75;")

        #expect(update?.serialNumber == -976_498_137)
        #expect(update?.litPixels == [
            GridPoint(column: 4, row: 2): 255,
            GridPoint(column: 3, row: 2): 191.25,
            GridPoint(column: 2, row: 2): 127.5,
            GridPoint(column: 1, row: 2): 63.75
        ])
    }

    @Test func parsesAnEmptyDisplay() {
        let update = RadioMessageParser.parse("1;-976498137;")

        #expect(update?.serialNumber == -976_498_137)
        #expect(update?.litPixels == [:])
    }

    @Test func ignoresUnsupportedRadioKinds() {
        #expect(RadioMessageParser.parse("2;-976498137;4,2,255;") == nil)
    }

    @Test func rejectsAMissingSerialNumber() {
        #expect(RadioMessageParser.parse("1;") == nil)
        #expect(RadioMessageParser.parse("1") == nil)
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
