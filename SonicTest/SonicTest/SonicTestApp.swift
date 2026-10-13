//
//  SonicTestApp.swift
//  SonicTest
//
//  Created by Hovik Melikyan on 13.10.26.
//

import SwiftUI


@main
struct SonicTestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


struct ContentView: View {

    @State private var player = Player()

    var body: some View {
        VStack(spacing: 24) {
            slider("Speed", value: $player.speed, in: 0.25...4)
            slider("Pitch", value: $player.pitch, in: 0.5...2)
            slider("Rate", value: $player.rate, in: 0.5...2)
            slider("Volume", value: $player.volume, in: 0.1...2)
            HStack(spacing: 32) {
                Button(player.isPlaying ? "Stop" : "Play") { player.toggle() }
                Button("Reset") { player.reset() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: 480)
    }


    private func slider(_ title: String, value: Binding<Float>, in range: ClosedRange<Float>) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue, format: .number.precision(.fractionLength(2)))
                    .monospacedDigit()
            }
            Slider(value: value, in: range)
        }
    }
}
