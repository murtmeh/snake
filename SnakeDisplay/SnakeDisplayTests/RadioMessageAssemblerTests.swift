//
//  RadioMessageAssemblerTests.swift
//  SnakeDisplayTests
//
//  Created by Måns Jäderlund on 2026-09-16.
//

import Testing
@testable import SnakeDisplay

struct RadioMessageAssemblerTests {
    @Test func returnsASingleLineMessageImmediately() {
        let assembler = RadioMessageAssembler()

        let message = assembler.feed("1;-976498137;4,2,255;!")

        #expect(message == "1;-976498137;4,2,255;")
    }

    @Test func joinsLinesWrappedMidFieldAndStripsFramingCharacters() {
        let assembler = RadioMessageAssembler()

        #expect(assembler.feed("1;1656601461;4,2,2:") == nil)
        #expect(assembler.feed("55;3,2,191.25;2,2,:") == nil)
        let message = assembler.feed("127.5;1,2,63.75;!")

        #expect(message == "1;1656601461;4,2,255;3,2,191.25;2,2,127.5;1,2,63.75;")
    }

    @Test func startsAFreshMessageAfterCompletingOne() {
        let assembler = RadioMessageAssembler()
        _ = assembler.feed("1;1;4,2,255;!")

        let message = assembler.feed("2;1;A;!")

        #expect(message == "2;1;A;")
    }

    @Test func resetDiscardsAnyPartiallyAssembledMessage() {
        let assembler = RadioMessageAssembler()
        _ = assembler.feed("1;1656601461;4,2,2:")

        assembler.reset()
        let message = assembler.feed("2;1;A;!")

        #expect(message == "2;1;A;")
    }
}
