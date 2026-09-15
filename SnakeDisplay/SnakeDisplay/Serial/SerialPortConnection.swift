//
//  SerialPortConnection.swift
//  SnakeDisplay
//
//  Created by Måns Jäderlund on 2026-09-15.
//

import Darwin
import Foundation

/// Opens a USB serial device and yields the newline-terminated lines it sends, one per element.
/// Reads on a dedicated `Thread` since it's a blocking syscall, and sends lines back through an `AsyncStream`.
actor SerialPortConnection {
    enum ConnectionError: LocalizedError {
        case alreadyOpen
        case openFailed(path: String, errno: Int32)
        case configurationFailed(errno: Int32)
        case readFailed(errno: Int32)

        var errorDescription: String? {
            switch self {
            case .alreadyOpen:
                return "A serial port is already open."
            case let .openFailed(path, errno):
                return "Couldn't open \(path): \(String(cString: strerror(errno)))."
            case let .configurationFailed(errno):
                return "Couldn't configure the serial port: \(String(cString: strerror(errno)))."
            case let .readFailed(errno):
                return "Lost the serial connection: \(String(cString: strerror(errno)))."
            }
        }
    }

    private var fileDescriptor: Int32?
    private var readThread: Thread?

    func open(path: String, baudRate: speed_t = speed_t(B9600)) throws -> AsyncStream<Result<String, Error>> {
        guard fileDescriptor == nil else {
            throw ConnectionError.alreadyOpen
        }

        let descriptor = path.withCString { Darwin.open($0, O_RDWR | O_NOCTTY | O_NONBLOCK) }
        guard descriptor >= 0 else {
            throw ConnectionError.openFailed(path: path, errno: errno)
        }

        do {
            try Self.configure(descriptor: descriptor, baudRate: baudRate)
        } catch {
            Darwin.close(descriptor)
            throw error
        }

        // Reads were only non-blocking to make `open` return immediately; switch back to
        // blocking so the read loop can wait for the next byte.
        let flags = fcntl(descriptor, F_GETFL, 0)
        _ = fcntl(descriptor, F_SETFL, flags & ~O_NONBLOCK)

        fileDescriptor = descriptor

        let (stream, continuation) = AsyncStream<Result<String, Error>>.makeStream()
        let thread = Thread {
            Self.readLoop(descriptor: descriptor, continuation: continuation)
        }
        thread.name = "SerialPortConnection.readLoop"
        thread.start()
        readThread = thread

        return stream
    }

    func close() {
        guard let descriptor = fileDescriptor else { return }
        fileDescriptor = nil
        readThread = nil
        Darwin.close(descriptor)
    }

    private static func configure(descriptor: Int32, baudRate: speed_t) throws {
        var settings = termios()
        guard tcgetattr(descriptor, &settings) == 0 else {
            throw ConnectionError.configurationFailed(errno: errno)
        }

        cfmakeraw(&settings)
        cfsetispeed(&settings, baudRate)
        cfsetospeed(&settings, baudRate)
        settings.c_cflag |= tcflag_t(CLOCAL | CREAD)

        guard tcsetattr(descriptor, TCSANOW, &settings) == 0 else {
            throw ConnectionError.configurationFailed(errno: errno)
        }
    }

    /// Runs on its own `Thread`. Reads raw bytes, splits them into lines, and sends each
    /// decoded line into `continuation`. Touches no actor-isolated state.
    private static func readLoop(descriptor: Int32, continuation: AsyncStream<Result<String, Error>>.Continuation) {
        var pending = [UInt8]()
        var chunk = [UInt8](repeating: 0, count: 1024)

        while true {
            let bytesRead = chunk.withUnsafeMutableBytes { buffer in
                read(descriptor, buffer.baseAddress, buffer.count)
            }

            if bytesRead > 0 {
                pending.append(contentsOf: chunk[0..<bytesRead])
                while let newlineIndex = pending.firstIndex(of: UInt8(ascii: "\n")) {
                    let lineBytes = pending[..<newlineIndex]
                    pending.removeSubrange(...newlineIndex)
                    if let line = String(bytes: lineBytes, encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines), !line.isEmpty {
                        continuation.yield(.success(line))
                    }
                }
            } else if bytesRead == 0 {
                continuation.finish()
                return
            } else if errno != EINTR {
                continuation.yield(.failure(ConnectionError.readFailed(errno: errno)))
                continuation.finish()
                return
            }
        }
    }
}
