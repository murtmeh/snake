//
//  ContentView.swift
//  SnakeDisplay
//
//  Created by Måns Jäderlund on 2026-09-15.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = PresentationViewModel()
    @State private var selectedPortPath: String?
    @State private var selectedBaudRate = PresentationViewModel.defaultBaudRate
    @State private var isDebugLogVisible = false

    private static let maximumGridColumns = 3

    private var gridColumns: [GridItem] {
        let columnCount = max(1, min(viewModel.displays.count, Self.maximumGridColumns))
        return Array(repeating: GridItem(.fixed(260), spacing: 16), count: columnCount)
    }

    var body: some View {
        VStack(spacing: 16) {
            SerialConnectionBar(
                viewModel: viewModel,
                selectedPortPath: $selectedPortPath,
                selectedBaudRate: $selectedBaudRate,
                isDebugLogVisible: $isDebugLogVisible
            )

            if isDebugLogVisible {
                SerialDebugLogView(messages: viewModel.rawMessageLog, onClear: viewModel.clearRawMessageLog)
            }

            if viewModel.displays.isEmpty {
                ContentUnavailableView(
                    "No microbits yet",
                    systemImage: "dot.radiowaves.left.and.right",
                    description: Text("Connect a serial port and start the game to see displays here.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(viewModel.displays) { display in
                            MicrobitGridView(display: display)
                        }
                    }
                    .padding(.vertical)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .frame(minWidth: 480, minHeight: 360)
        .onAppear {
            viewModel.reset()
            viewModel.refreshAvailablePortPaths()
            if selectedPortPath == nil, let onlyPortPath = viewModel.availablePortPaths.first,
               viewModel.availablePortPaths.count == 1 {
                selectedPortPath = onlyPortPath
            }
        }
    }
}

#Preview {
    ContentView()
}
