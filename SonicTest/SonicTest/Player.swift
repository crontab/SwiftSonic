//
//  Player.swift
//  SonicTest
//
//  Created by Hovik Melikyan on 13.10.26.
//

import AVFoundation
import SwiftSonic


@MainActor @Observable
final class Player {

    var speed: Float = 1 { didSet { configure() } }
    var pitch: Float = 1 { didSet { configure() } }
    var rate: Float = 1 { didSet { configure() } }
    var volume: Float = 1 { didSet { configure() } }

    var isPlaying: Bool { engine != nil }


    func toggle() {
        if isPlaying {
            stop()
        } else {
            play()
        }
    }


    func reset() {
        speed = 1
        pitch = 1
        rate = 1
        volume = 1
    }


    // Private

    private static let sampleRate = 22050 // talking.bin: 16-bit mono PCM

    private var engine: AVAudioEngine?
    private var feeder: Feeder?

    private func play() {
        do {
            let feeder = try Feeder(samples: Self.loadSamples(), sampleRate: Self.sampleRate)
            self.feeder = feeder
            configure()
            let format = AVAudioFormat(standardFormatWithSampleRate: Double(Self.sampleRate), channels: 1)!
            let node = Self.makeSourceNode(format: format, feeder: feeder)
            let engine = AVAudioEngine()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
#if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
#endif
            try engine.start()
            self.engine = engine
        } catch {
            feeder = nil
            print("Playback failed: \(error)")
        }
    }


    private func stop() {
        engine?.stop()
        engine = nil
        feeder = nil
    }


    private func configure() {
        feeder?.configure(speed: speed, pitch: pitch, rate: rate, volume: volume)
    }


    private static func loadSamples() throws -> [Int16] {
        guard let url = Bundle.main.url(forResource: "talking", withExtension: "bin") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try Data(contentsOf: url)
        var samples = [Int16](repeating: 0, count: data.count / 2)
        _ = samples.withUnsafeMutableBytes { data.copyBytes(to: $0) }
        return samples
    }


    // The render block runs on the audio thread, so it must not inherit main actor isolation
    nonisolated private static func makeSourceNode(format: AVAudioFormat, feeder: Feeder) -> AVAudioSourceNode {
        AVAudioSourceNode(format: format) { _, _, frameCount, bufferList in
            let buffer = UnsafeMutableAudioBufferListPointer(bufferList)[0]
            feeder.render(into: UnsafeMutableBufferPointer(start: buffer.mData?.assumingMemoryBound(to: Float.self), count: Int(frameCount)))
            return noErr
        }
    }
}


// Plays the samples in a loop; parameters can be changed from any thread while playing

private final class Feeder: @unchecked Sendable {

    init(samples: [Int16], sampleRate: Int) throws {
        sonic = try Sonic(sampleRate: sampleRate, channels: 1)
        self.samples = samples
    }


    func configure(speed: Float, pitch: Float, rate: Float, volume: Float) {
        lock.withLock {
            sonic.speed = speed
            sonic.pitch = pitch
            sonic.rate = rate
            sonic.volume = volume
        }
    }


    func render(into out: UnsafeMutableBufferPointer<Float>) {
        lock.withLock {
            var filled = 0
            while filled < out.count {
                let count = sonic.read(into: UnsafeMutableBufferPointer(rebasing: out[filled...]))
                filled += count
                if count == 0, (try? feed()) == nil {
                    break
                }
            }
            UnsafeMutableBufferPointer(rebasing: out[filled...]).update(repeating: 0)
        }
    }


    // Private

    private let sonic: Sonic
    private let samples: [Int16]
    private var position = 0
    private var flushed = false
    private let lock = NSLock()

    private func feed() throws {
        if position < samples.count {
            let end = min(position + 1024, samples.count)
            try samples[position..<end].withUnsafeBufferPointer { try sonic.write($0) }
            position = end
        } else if !flushed {
            try sonic.flush()
            flushed = true
        } else {
            position = 0
            flushed = false
        }
    }
}
