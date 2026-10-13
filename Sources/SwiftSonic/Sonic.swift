//
//  Sonic.swift
//  SwiftSonic
//
//  Created by Hovik Melikyan on 13.10.26.
//

import Foundation
import CSonic


// Samples are interleaved; one frame holds one sample per channel. Float samples are in -1...1.

public final class Sonic {

    public let sampleRate: Int
    public let channels: Int


    public init(sampleRate: Int, channels: Int) throws {
        guard let stream = sonicCreateStream(Int32(clamping: sampleRate), Int32(clamping: channels)) else {
            throw SonicError.outOfMemory
        }
        self.stream = stream
        self.sampleRate = Int(sonicGetSampleRate(stream))
        self.channels = Int(sonicGetNumChannels(stream))
    }


    public var speed: Float {
        get { sonicGetSpeed(stream) }
        set { sonicSetSpeed(stream, newValue) }
    }


    public var pitch: Float {
        get { sonicGetPitch(stream) }
        set { sonicSetPitch(stream, newValue) }
    }


    public var rate: Float {
        get { sonicGetRate(stream) }
        set { sonicSetRate(stream, newValue) }
    }


    public var volume: Float {
        get { sonicGetVolume(stream) }
        set { sonicSetVolume(stream, newValue) }
    }


    public var highQuality: Bool {
        get { sonicGetQuality(stream) != 0 }
        set { sonicSetQuality(stream, newValue ? 1 : 0) }
    }


    public var availableFrames: Int {
        Int(sonicSamplesAvailable(stream))
    }


    public func write(_ samples: UnsafeBufferPointer<Int16>) throws {
        guard sonicWriteShortToStream(stream, samples.baseAddress, frames(samples.count)) != 0 else {
            throw SonicError.outOfMemory
        }
    }


    public func write(_ samples: UnsafeBufferPointer<Float>) throws {
        guard sonicWriteFloatToStream(stream, samples.baseAddress, frames(samples.count)) != 0 else {
            throw SonicError.outOfMemory
        }
    }


    public func write(_ samples: [Int16]) throws {
        try samples.withUnsafeBufferPointer { try write($0) }
    }


    public func write(_ samples: [Float]) throws {
        try samples.withUnsafeBufferPointer { try write($0) }
    }


    // Returns the number of frames read
    public func read(into buffer: UnsafeMutableBufferPointer<Int16>) -> Int {
        guard let base = buffer.baseAddress else { return 0 }
        return Int(sonicReadShortFromStream(stream, base, frames(buffer.count)))
    }


    // Returns the number of frames read
    public func read(into buffer: UnsafeMutableBufferPointer<Float>) -> Int {
        guard let base = buffer.baseAddress else { return 0 }
        return Int(sonicReadFloatFromStream(stream, base, frames(buffer.count)))
    }


    public func read() -> [Int16] {
        [Int16](unsafeUninitializedCapacity: availableFrames * channels) { buffer, count in
            count = read(into: buffer) * channels
        }
    }


    public func read() -> [Float] {
        [Float](unsafeUninitializedCapacity: availableFrames * channels) { buffer, count in
            count = read(into: buffer) * channels
        }
    }


    public func flush() throws {
        guard sonicFlushStream(stream) != 0 else {
            throw SonicError.outOfMemory
        }
    }


    // Private

    private let stream: OpaquePointer

    private func frames(_ count: Int) -> Int32 {
        Int32(clamping: count / channels)
    }

    deinit {
        sonicDestroyStream(stream)
    }
}


public enum SonicError: LocalizedError {
    case outOfMemory

    public var errorDescription: String? {
        switch self {
            case .outOfMemory: "Sonic: out of memory"
        }
    }
}
