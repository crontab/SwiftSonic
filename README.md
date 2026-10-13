SwiftSonic
==========

Swift wrapper for [Sonic](https://github.com/waywardgeek/sonic), Bill Cox's
library for speeding up, slowing down and pitch-shifting speech.

## Installation

Add the package with Swift Package Manager and depend on the `SwiftSonic`
product:

```swift
.package(url: "https://github.com/crontab/SwiftSonic.git", branch: "master")
```

Requires iOS 18 or macOS 15.

## Usage

```swift
import SwiftSonic

let sonic = try Sonic(sampleRate: 22050, channels: 1)
sonic.speed = 2

try sonic.write(chunk)               // [Int16] or [Float]
let output: [Int16] = sonic.read()

try sonic.flush()                    // at the end of the stream
let tail: [Int16] = sonic.read()
```

Samples are interleaved, Float samples are in the -1...1 range. `speed`,
`pitch`, `rate`, `volume` and `highQuality` can be changed while streaming.
For real-time use there are `write(_:)` and `read(into:)` overloads that take
buffer pointers. A `Sonic` instance is not thread-safe.

## Test app

`SonicTest/SonicTest.xcodeproj` is a SwiftUI app for iOS and macOS that loops
a speech sample, with sliders for speed, pitch, rate and volume.

## License

The Sonic library (`Sources/CSonic`) is by Bill Cox and is licensed under
the Apache License 2.0 (see `LICENSE`). Everything else is placed into the
public domain (see `UNLICENSE`).
