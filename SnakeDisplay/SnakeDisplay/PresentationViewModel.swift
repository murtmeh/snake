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

    private(set) var displays: [MicrobitDisplay] = []
    private(set) var connectionState: ConnectionState = .disconnected
    private(set) var availablePortPaths: [String] = []
    private(set) var rawMessageLog: [String] = []

    private let connection: SerialPortConnection
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

        guard let update = RadioMessageParser.parse(line) else { return }
        apply(update)
    }

    func apply(_ update: RadioDisplayUpdate) {
        if let index = displays.firstIndex(where: { $0.serialNumber == update.serialNumber }) {
            displays[index].litPixels = update.litPixels
        } else if displays.count < Self.maximumMicrobitCount {
            displays.append(MicrobitDisplay(serialNumber: update.serialNumber, litPixels: update.litPixels))
        }
    }
}
