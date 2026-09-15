//
//  SerialPortScanner.swift
//  SnakeDisplay
//
//  Created by Måns Jäderlund on 2026-09-15.
//

import Foundation

/// Finds candidate USB serial devices under `/dev`, for example `/dev/cu.usbmodem1102`.
nonisolated enum SerialPortScanner {
    static func availablePortPaths() -> [String] {
        let devicesDirectory = "/dev"
        guard let entries = try? FileManager.default.contentsOfDirectory(atPath: devicesDirectory) else {
            return []
        }
        return entries
            .filter { $0.hasPrefix("cu.usbmodem") || $0.hasPrefix("cu.usbserial") }
            .sorted()
            .map { "\(devicesDirectory)/\($0)" }
    }
}
