# swift-safe-subscript

A tiny Swift package that adds a `subscript(safe:)` to every `Collection` and `MutableCollection`. Out-of-bounds reads return `nil` instead of trapping; out-of-bounds writes are silent no-ops.

```swift
let array = [1, 2, 3]
array[safe: 0]    // 1
array[safe: 99]   // nil
array[safe: -1]   // nil
```

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
	.package(url: "https://github.com/<your-user>/swift-safe-subscript.git", from: "1.0.0"),
],
targets: [
	.target(name: "YourTarget", dependencies: [
		.product(name: "SafeSubscript", package: "swift-safe-subscript"),
	]),
]
```

Or in Xcode: **File → Add Package Dependencies…** and paste the repository URL.

## Usage

It works on any `Collection`, regardless of the index type:

```swift
import SafeSubscript

// Array (Int index)
[10, 20, 30][safe: 1]                          // Optional(20)
[10, 20, 30][safe: 10]                         // nil

// ArraySlice (non-zero startIndex)
let slice = [0, 1, 2, 3, 4][2...]
slice[safe: 2]                                  // Optional(2)
slice[safe: 0]                                  // nil  (inside the array but outside the slice)

// String / Substring (String.Index)
"hello"[safe: "hello".startIndex]               // Optional("h")
"hello"[safe: "hello".endIndex]                 // nil

// Dictionary / Set (opaque Index)
let dict = ["a": 1, "b": 2]
dict[safe: dict.startIndex]                     // Optional((key: "a", value: 1))
dict[safe: dict.endIndex]                       // nil

// Range
(10..<15)[safe: 12]                             // Optional(12)
(10..<15)[safe: 99]                             // nil
```

`MutableCollection` adds a setter. Writes outside the valid range — or assignments of `nil` — are no-ops:

```swift
var array = [1, 2, 3]
array[safe: 1] = 20    // [1, 20, 3]
array[safe: 99] = 99   // [1, 20, 3] — unchanged
array[safe: 1] = nil   // [1, 20, 3] — unchanged
```

## Why not implement `subscript(safe:)` with `indices.contains`?

The obvious one-liner is to ask the collection itself whether the index is valid:

```swift
extension Collection {
	public subscript(safe index: Index) -> Element? {
		indices.contains(index) ? self[index] : nil
	}
}
```

This is correct but loses badly on any collection where `indices.contains` is O(n) — which is most of them. Only `RandomAccessCollection`s with `Range<Int>` indices (`Array`, `Range`, `UnsafeBufferPointer`, …) get O(1) from `indices.contains`. For `String`, `Substring`, `Set`, `Dictionary`, and friends, `indices` returns a `DefaultIndices` that walks the collection linearly to answer `.contains`.

This package compares `index` against `startIndex` and `endIndex` directly:

```swift
extension Collection {
	@inlinable
	public subscript(safe index: Index) -> Element? {
		index >= startIndex && index < endIndex ? self[index] : nil
	}
}
```

Two `Comparable` comparisons. O(1) on every standard-library collection.

## Benchmarks

Measured on Apple Silicon with Swift 6.3 in release mode, best of 15 trials. Both versions are compiled with `@inlinable`, given the same probe arrays (mixing in-bounds and out-of-bounds indices), and run through the same harness — so the only difference is the implementation of `subscript(safe:)` itself. Input values are runtime-perturbed so the optimizer can't constant-fold the loop.

| Collection             | n     | `startIndex`/`endIndex` impl | `indices.contains` impl  | Speedup     |
| :--------------------- | ----: | ---------------------------: | -----------------------: | ----------: |
| `Array<Int>`           | 1 000 |                 3 560 ns/op  |              4 573 ns/op |       1.28× |
| `String`               | 1 000 |                10 949 ns/op  |          1 612 572 ns/op |     147.28× |
| `Dictionary<Int, Int>` |   500 |                   378 ns/op  |            297 646 ns/op |     788.47× |

The `Array` ratio is noise-dominated and varies run to run (typically 1.0–2.0×) because `Array.indices` is a `Range<Int>` with O(1) `.contains` — the absolute gap is only a few hundred nanoseconds across 10 000 probes. For everything backed by `DefaultIndices` (`String`, `Substring`, `Set`, `Dictionary`, …), the `indices.contains` implementation collapses to O(n) per lookup and the speedup is stable.

Reproduce locally:

```sh
swift run -c release SafeSubscriptBenchmarks
```

## Testing

```sh
swift test
```

The suite covers `Array`, `ArraySlice` (non-zero `startIndex`), `ContiguousArray`, `String`, `Substring`, `Set`, `Dictionary`, `Range`, lazy/repeated wrappers, and `Int.min` / `Int.max` probes, plus mutable-set semantics for `MutableCollection`.

## License

[The Unlicense](LICENSE.md) — public domain, no attribution required.
