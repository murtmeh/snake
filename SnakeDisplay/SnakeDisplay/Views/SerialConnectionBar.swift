//
//  SerialConnectionBar.swift
//  SnakeDisplay
//
//  Created by Måns Jäderlund on 2026-09-15.
//

import SwiftUI

struct SerialConnectionBar: View {
    private static let portRefreshInterval = Duration.seconds(1)

    let viewModel: PresentationViewModel
    @Binding var selectedPortPath: String?
    @Binding var selectedBaudRate: Int
    @Binding var isDebugLogVisible: Bool

    var body: some View {
        HStack(spacing: 12) {
            switch viewModel.connectionState {
            case .disconnected, .failed:
                portPicker
                baudRatePicker
                Button("Connect") {
                    guard let selectedPortPath else { return }
                    Task { await viewModel.connect(to: selectedPortPath, baudRate: selectedBaudRate) }
                }
                .disabled(selectedPortPath == nil)

                if case let .failed(message) = viewModel.connectionState {
                    Text(message)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }

            case .connecting:
                ProgressView()
                    .controlSize(.small)
                Text("Connecting…")
                    .foregroundStyle(.secondary)

            case let .connected(portPath):
                Label("Connected to \((portPath as NSString).lastPathComponent)", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Button("Disconnect") {
                    Task { await viewModel.disconnect() }
                }
            }

            Spacer()

            Button("Clear", systemImage: "trash", action: viewModel.reset)
                .labelStyle(.iconOnly)
                .help("Clear all microbit displays")

            Toggle("Debug log", systemImage: "ladybug", isOn: $isDebugLogVisible)
                .toggleStyle(.button)
                .labelStyle(.iconOnly)
                .help("Show raw serial messages")
        }
        // The port picker is a native macOS menu, which opens on mouse-down before any
        // SwiftUI tap gesture can react. Instead of refreshing on click, keep the list
        // current with periodic polling.
        .task {
            while !Task.isCancelled {
                if case .connected = viewModel.connectionState {
                    // No picker is visible while connected; nothing to refresh.
                } else {
                    viewModel.refreshAvailablePortPaths()
                    if let selectedPortPath, !viewModel.availablePortPaths.contains(selectedPortPath) {
                        self.selectedPortPath = nil
                    }
                }
                try? await Task.sleep(for: Self.portRefreshInterval)
            }
        }
    }

    private var portPicker: some View {
        Picker("Serial port", selection: $selectedPortPath) {
            Text("Select a port").tag(String?.none)
            ForEach(viewModel.availablePortPaths, id: \.self) { path in
                Text((path as NSString).lastPathComponent).tag(String?.some(path))
            }
        }
        .frame(maxWidth: 260)
    }

    private var baudRatePicker: some View {
        Picker("Baud rate", selection: $selectedBaudRate) {
            ForEach(PresentationViewModel.standardBaudRates, id: \.self) { baudRate in
                Text("\(baudRate)").tag(baudRate)
            }
        }
        .frame(maxWidth: 200)
    }
}
