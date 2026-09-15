//
//  SerialDebugLogView.swift
//  SnakeDisplay
//
//  Created by Måns Jäderlund on 2026-09-15.
//

import SwiftUI

struct SerialDebugLogView: View {
    let messages: [String]
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Serial messages (\(messages.count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Clear", action: onClear)
                    .font(.caption)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                            Text(message)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .id(index)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: messages.count) {
                    guard let lastIndex = messages.indices.last else { return }
                    proxy.scrollTo(lastIndex, anchor: .bottom)
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(.black.opacity(0.85))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    SerialDebugLogView(
        messages: [
            "1;-97649137;4,2;3,2;2,2;1,2;",
            "1;-97649137;3,2;2,2;1,2;0,2;",
            "garbled line"
        ],
        onClear: {}
    )
    .padding()
}
