//
//  PresentationViewModelTests.swift
//  SnakeDisplayTests
//
//  Created by Måns Jäderlund on 2026-09-15.
//

import Testing
@testable import SnakeDisplay

@MainActor
struct PresentationViewModelTests {
    @Test func addsANewMicrobitOnItsFirstUpdate() {
        let viewModel = PresentationViewModel()

        viewModel.apply(RadioDisplayUpdate(serialNumber: 1, litPixels: [GridPoint(column: 0, row: 0): 255]))

        #expect(viewModel.displays.map(\.serialNumber) == [1])
        #expect(viewModel.displays.first?.litPixels == [GridPoint(column: 0, row: 0): 255])
    }

    @Test func replacesAnExistingMicrobitsPixelsInPlace() {
        let viewModel = PresentationViewModel()
        viewModel.apply(RadioDisplayUpdate(serialNumber: 1, litPixels: [GridPoint(column: 0, row: 0): 255]))
        viewModel.apply(RadioDisplayUpdate(serialNumber: 2, litPixels: [GridPoint(column: 1, row: 1): 255]))

        viewModel.apply(RadioDisplayUpdate(serialNumber: 1, litPixels: [GridPoint(column: 4, row: 4): 127.5]))

        #expect(viewModel.displays.map(\.serialNumber) == [1, 2])
        #expect(viewModel.displays.first?.litPixels == [GridPoint(column: 4, row: 4): 127.5])
    }

    @Test func ignoresMicrobitsBeyondTheMaximum() {
        let viewModel = PresentationViewModel()
        for serialNumber in Int32(1)...Int32(PresentationViewModel.maximumMicrobitCount) {
            viewModel.apply(RadioDisplayUpdate(serialNumber: serialNumber, litPixels: [:]))
        }

        viewModel.apply(RadioDisplayUpdate(serialNumber: 999, litPixels: [GridPoint(column: 0, row: 0): 255]))

        #expect(viewModel.displays.count == PresentationViewModel.maximumMicrobitCount)
        #expect(!viewModel.displays.contains { $0.serialNumber == 999 })
    }

    @Test func resetClearsRememberedDisplays() {
        let viewModel = PresentationViewModel()
        viewModel.apply(RadioDisplayUpdate(serialNumber: 1, litPixels: [:]))

        viewModel.reset()

        #expect(viewModel.displays.isEmpty)
    }
}
