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

    /// A thread-safe stop flag the read loop polls between reads. We can't rely on closing the
    /// descriptor to unblock a thread stuck in a blocking `read()` on it (on macOS that can leave
    /// `close()` itself waiting on the pending read), so cancellation instead happens by having the
    /// read loop wait on `poll` with a timeout and check this flag each time it wakes up.
    private final class StopSignal: @unchecked Sendable {
        private let lock = NSLock()
        private var stopped = false

        func signal() {
            lock.lock()
            stopped = true
            lock.unlock()
        }

        var isStopped: Bool {
            lock.lock()
            defer { lock.unlock() }
            return stopped
        }
    }

    private static let pollTimeoutMilliseconds: Int32 = 200

    private var fileDescriptor: Int32?
    private var readThread: Thread?
    private var continuation: AsyncStream<Result<String, Error>>.Continuation?
    private var stopSignal: StopSignal?

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
        // blocking so a `read()` call, once `poll` says data is ready, returns it right away.
        let flags = fcntl(descriptor, F_GETFL, 0)
        _ = fcntl(descriptor, F_SETFL, flags & ~O_NONBLOCK)

        fileDescriptor = descriptor

        let (stream, continuation) = AsyncStream<Result<String, Error>>.makeStream()
        self.continuation = continuation
        let stopSignal = StopSignal()
        self.stopSignal = stopSignal
        let thread = Thread {
            Self.readLoop(descriptor: descriptor, continuation: continuation, stopSignal: stopSignal)
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
        // Signal the read loop before touching the descriptor: it notices at its next `poll`
        // wakeup (at most `pollTimeoutMilliseconds` away) and stops on its own, so this call
        // never has to wait on it.
        stopSignal?.signal()
        stopSignal = nil
        // Finish the stream ourselves too. Any `yield` the read loop still manages to make after
        // this (e.g. a read error from the descriptor closing under it) becomes a no-op, so it
        // can't race a `.failure` result past this intentional close.
        continuation?.finish()
        continuation = nil
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

    /// Runs on its own `Thread`. Waits for the descriptor to have data using a bounded `poll` (so
    /// `stopSignal` is checked regularly instead of parking in an uninterruptible blocking `read`),
    /// then reads raw bytes, splits them into lines, and sends each decoded line into `continuation`.
    /// Touches no actor-isolated state.
    private static func readLoop(
        descriptor: Int32,
        continuation: AsyncStream<Result<String, Error>>.Continuation,
        stopSignal: StopSignal
    ) {
        var pending = [UInt8]()
        var chunk = [UInt8](repeating: 0, count: 1024)

        while !stopSignal.isStopped {
            var pollDescriptor = pollfd(fd: descriptor, events: Int16(POLLIN), revents: 0)
            let pollResult = poll(&pollDescriptor, 1, pollTimeoutMilliseconds)

            if stopSignal.isStopped {
                return
            }

            if pollResult == 0 {
                continue // Timed out with no data; loop back and re-check stopSignal.
            }

            if pollResult < 0 {
                if errno == EINTR {
                    continue
                }
                continuation.yield(.failure(ConnectionError.readFailed(errno: errno)))
                continuation.finish()
                return
            }

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
            } else if errno != EINTR && errno != EAGAIN {
                continuation.yield(.failure(ConnectionError.readFailed(errno: errno)))
                continuation.finish()
                return
            }
        }
    }
}
