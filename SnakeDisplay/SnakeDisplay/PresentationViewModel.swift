//
//  PresentationViewModel.swift
//  SnakeDisplay
//
//  Created by Måns Jäderlund on 2026-09-15.
//

import Darwin
import Foundation
import Observation

/// Drives the presentation screen: owns the serial connection, decodes incoming radio
/// messages, and keeps the on-screen state.
@MainActor
@Observable
final class PresentationViewModel {
    enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case connected(portPath: String)
        case failed(message: String)
    }

    static let maximumMicrobitCount = 6
    static let maximumLoggedMessages = 500
    static let defaultBaudRate = 115200
    static let standardBaudRates = [1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 57600, 115200]
    static let buttonFlashDuration = Duration.milliseconds(200)

    private(set) var displays: [MicrobitDisplay] = []
    private(set) var connectionState: ConnectionState = .disconnected
    private(set) var availablePortPaths: [String] = []
    private(set) var rawMessageLog: [String] = []

    private let connection: SerialPortConnection
    private let messageAssembler = RadioMessageAssembler()
    private var readTask: Task<Void, Never>?

    init(connection: SerialPortConnection = SerialPortConnection()) {
        self.connection = connection
    }

    func refreshAvailablePortPaths() {
        availablePortPaths = SerialPortScanner.availablePortPaths()
    }

    func connect(to path: String, baudRate: Int = defaultBaudRate) async {
        guard connectionState != .connecting else { return }

        connectionState = .connecting
        rawMessageLog = []
        messageAssembler.reset()
        do {
            let stream = try await connection.open(path: path, baudRate: speed_t(baudRate))
            connectionState = .connected(portPath: path)

            readTask = Task {
                for await result in stream {
                    switch result {
                    case let .success(line):
                        self.handle(line: line)
                    case let .failure(error):
                        self.connectionState = .failed(message: error.localizedDescription)
                    }
                }
            }
        } catch {
            connectionState = .failed(message: error.localizedDescription)
        }
    }

    func disconnect() async {
        readTask?.cancel()
        readTask = nil
        await connection.close()
        connectionState = .disconnected
    }

    func reset() {
        displays = []
    }

    func clearRawMessageLog() {
        rawMessageLog = []
    }

    private func handle(line: String) {
        rawMessageLog.append(line)
        if rawMessageLog.count > Self.maximumLoggedMessages {
            rawMessageLog.removeFirst(rawMessageLog.count - Self.maximumLoggedMessages)
        }

        guard let message = messageAssembler.feed(line) else { return }

        switch RadioMessageParser.parse(message) {
        case let .displayUpdate(update):
            apply(update)
        case let .buttonPress(event):
            apply(event)
        case let .death(event):
            apply(event)
        case nil:
            break
        }
    }

    func apply(_ update: RadioDisplayUpdate) {
        guard let index = ensureDisplayIndex(for: update.serialNumber) else { return }
        displays[index].litPixels = update.litPixels
        displays[index].isDead = false
    }

    func apply(_ event: DeathEvent) {
        guard let index = ensureDisplayIndex(for: event.serialNumber) else { return }
        displays[index].litPixels = [:]
        displays[index].isDead = true
    }

    func apply(_ event: ButtonPressEvent) {
        guard let index = ensureDisplayIndex(for: event.serialNumber) else { return }
        displays[index].pressedButton = event.button

        Task {
            try? await Task.sleep(for: Self.buttonFlashDuration)
            guard let index = self.displays.firstIndex(where: { $0.serialNumber == event.serialNumber }) else { return }
            if self.displays[index].pressedButton == event.button {
                self.displays[index].pressedButton = nil
            }
        }
    }

    private func ensureDisplayIndex(for serialNumber: Int32) -> Int? {
        if let index = displays.firstIndex(where: { $0.serialNumber == serialNumber }) {
            return index
        }
        guard displays.count < Self.maximumMicrobitCount else { return nil }
        displays.append(MicrobitDisplay(serialNumber: serialNumber, litPixels: [:]))
        return displays.count - 1
    }
}
