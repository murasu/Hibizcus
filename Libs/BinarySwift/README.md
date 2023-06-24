[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) ![platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20OSX-333333.svg) ![pod](https://img.shields.io/cocoapods/v/BinarySwift.svg) [![Build Status](https://travis-ci.org/Szaq/BinarySwift.svg?branch=master)](https://travis-ci.org/Szaq/BinarySwift)
# BinarySwift

BinarySwift is a pure-swift library for parsing binary data. It contains two components - BinaryReader which can be used to parse
                   binary data in non-mutating environment,
                   and BinaryDataReader which keeps index of last read byte and
                   automatically updates it.

Using this library you can read:
- UInt(8/16/32/64)
- Int(8/16/32/64)
- Float(32,64)
- Null-terminated UTF8 string
- UTF8 String of known size
                    
# How to use

There are various initializers of `BinaryData`. Most notably `public init(data: [UInt8], bigEndian: Bool = default)` and `public init(data: NSData, bigEndian: Bool = default)`.

BinaryData is a non-mutating struct, so can safely be created using `let`.

Parsing IP frame header with `BinaryReader` is very simple:

```swift

struct IPHeader {
  let version: UInt8
  let headerLength: UInt8
  let typeOfService: UInt8
  let length: UInt16
  let id: UInt16
  let offset: UInt16
  let timeToLive: UInt8
  let proto:UInt8
  let checksum: UInt16
  let source: in_addr
  let destination: in_addr
}

let nsData = ...
let data = BinaryData(data: nsData)

let header = IPHeader(version: try data.get(0),
                    headerLength: try data.get(1),
                    typeOfService: try data.get(2),
                    length: try data.get(3),
                    id: try data.get(5),
                    offset: try data.get(7),
                    timeToLive: try data.get(8),
                    proto: try data.get(9),
                    checksum: try data.get(10),
                    source: in_addr(s_addr: try data.get(12)),
                    destination: in_addr(s_addr: try data.get(16)))

```

If mutating reference types are not a problem for you then with BinaryDataReader it is even simpler:
```swift

struct IPHeader {
  let version: UInt8
  let headerLength: UInt8
  let typeOfService: UInt8
  let length: UInt16
  let id: UInt16
  let offset: UInt16
  let timeToLive: UInt8
  let proto:UInt8
  let checksum: UInt16
  let source: in_addr
  let destination: in_addr
}

let nsData = ...
let data = BinaryData(data: nsData)
let reader = BinaryDataReader(data)

let header = IPHeader(version: try reader.read(),
                    headerLength: try reader.read(),
                    typeOfService: try reader.read(),
                    length: try reader.read(),
                    id: try reader.read(),
                    offset: try reader.read(),
                    timeToLive: try reader.read(),
                    proto: try reader.read(),
                    checksum: try reader.read(),
                    source: in_addr(s_addr: try reader.read()),
                    destination: in_addr(s_addr: try reader.read()))

```
You can even pass `reader` down to other functions, because it is a `class` and reference semantics applies.

This library is perfect compromise. Neither magic nor too verbose.

# Contributions
Contributions are more than welcome. Please send your PRs / Issues / Whatever comes to your mind.
