//
//  RadioMessageAssembler.swift
//  SnakeDisplay
//
//  Created by Måns Jäderlund on 2026-09-16.
//

/// Reassembles a full radio message from the serial lines the relay splits it across.
///
/// The relay wraps a long message onto multiple lines: every line but the last ends with
/// `:`, and the last ends with `!`. Both framing characters are stripped and the remaining
/// text from every line is concatenated verbatim, since the wrap can land mid-field.
nonisolated final class RadioMessageAssembler {
    private var buffer = ""

    /// Feeds one serial line into the assembler. Returns the completed message once `line`
    /// carries the terminating `!`, otherwise `nil` while the message is still being assembled.
    func feed(_ line: String) -> String? {
        guard let terminatorIndex = line.firstIndex(of: "!") else {
            buffer += line.filter { $0 != ":" }
            return nil
        }

        buffer += line[..<terminatorIndex].filter { $0 != ":" }
        defer { buffer = "" }
        return buffer
    }

    func reset() {
        buffer = ""
    }
}
