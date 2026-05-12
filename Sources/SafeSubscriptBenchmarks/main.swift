import Dispatch
import Foundation
import SafeSubscript

extension Collection {
	@inlinable
	subscript(safeContains index: Index) -> Element? {
		indices.contains(index) ? self[index] : nil
	}
}

// Sinking results into a mutable global is an unambiguous side effect — the
// optimizer must preserve every call, which prevents it from eliminating the
// benchmark loops. `_fixLifetime`/`withExtendedLifetime` aren't strong enough
// for trivial value types like `Int`.
nonisolated(unsafe) var blackHoleSink: Int = 0

@inline(never)
func blackHole(_ value: Int) {
	blackHoleSink = blackHoleSink &+ value
}

func measure(iterations: Int, trials: Int = 15, _ body: () -> Void) -> Double {
	// Warm up once so the first trial isn't penalised by code/data caches.
	body()

	var best = Double.infinity
	for _ in 0..<trials {
		let start = DispatchTime.now().uptimeNanoseconds
		for _ in 0..<iterations { body() }
		let elapsed = Double(DispatchTime.now().uptimeNanoseconds - start)
		best = min(best, elapsed / Double(iterations))
	}
	return best
}

let safeLabel = "startIndex/endIndex impl"
let containsLabel = "indices.contains impl"

func report(label: String, nsPerOp: Double) {
	let formatted = String(format: "%10.2f ns/op", nsPerOp)
	print("  \(label.padding(toLength: 32, withPad: " ", startingAt: 0))\(formatted)")
}

func speedup(safe: Double, baseline: Double) {
	let ratio = baseline / safe
	let formatted = String(format: "%.2fx", ratio)
	print("  -> \(safeLabel) is \(formatted) the speed of \(containsLabel)\n")
}

// Inputs are hidden behind `@inline(never)` accessors so the optimizer cannot
// constant-fold probe values or vectorize the loops away. The perturbation
// (`CommandLine.argc`) makes element values genuinely opaque to the compiler
// even with LTO — it's 0 in practice, but the compiler doesn't know that.

let perturbation = Int(CommandLine.argc) &- 1

let arrayCount = 1_000
let backingArray: [Int] = (0..<arrayCount).map { $0 &+ perturbation }
let backingArrayProbes: [Int] = (0..<10_000).map { _ in Int.random(in: -200 ... (arrayCount + 200)) }

let backingString = String(repeating: "abcdefghij", count: 100)
let backingStringIndices: [String.Index] = Array(backingString.indices) + [backingString.endIndex]

let backingDict = Dictionary(uniqueKeysWithValues: (0..<500).map { (key: $0, value: $0 &+ perturbation) })
let backingDictIndices: [Dictionary<Int, Int>.Index] = Array(backingDict.indices) + [backingDict.endIndex]

@inline(never) func array() -> [Int] { backingArray }
@inline(never) func arrayProbes() -> [Int] { backingArrayProbes }
@inline(never) func string() -> String { backingString }
@inline(never) func stringIndices() -> [String.Index] { backingStringIndices }
@inline(never) func dict() -> [Int: Int] { backingDict }
@inline(never) func dictIndices() -> [Dictionary<Int, Int>.Index] { backingDictIndices }

// Per-scenario, non-generic benchmark bodies. Unifying them behind a generic
// helper loses generic specialization through `@inline(never)` and roughly
// halves measured throughput.

@inline(never)
func arraySafe() {
	let source = array()
	var sink = 0
	for index in arrayProbes() {
		if let value = source[safe: index] { sink &+= value }
	}
	blackHole(sink)
}

@inline(never)
func arrayIndicesContains() {
	let source = array()
	var sink = 0
	for index in arrayProbes() {
		if let value = source[safeContains: index] { sink &+= value }
	}
	blackHole(sink)
}

@inline(never)
func stringSafe() {
	let source = string()
	var sink = 0
	for index in stringIndices() {
		if let character = source[safe: index] { sink &+= Int(character.asciiValue ?? 0) }
	}
	blackHole(sink)
}

@inline(never)
func stringIndicesContains() {
	let source = string()
	var sink = 0
	for index in stringIndices() {
		if let character = source[safeContains: index] { sink &+= Int(character.asciiValue ?? 0) }
	}
	blackHole(sink)
}

@inline(never)
func dictionarySafe() {
	let source = dict()
	var sink = 0
	for index in dictIndices() {
		if let entry = source[safe: index] { sink &+= entry.value }
	}
	blackHole(sink)
}

@inline(never)
func dictionaryIndicesContains() {
	let source = dict()
	var sink = 0
	for index in dictIndices() {
		if let entry = source[safeContains: index] { sink &+= entry.value }
	}
	blackHole(sink)
}

print("swift-safe-subscript benchmarks")
print("================================\n")

print("Array<Int>  (n=\(array().count), probes=\(arrayProbes().count), RandomAccessCollection / Int index)")
let arraySafeNs = measure(iterations: 200) { arraySafe() }
let arrayContainsNs = measure(iterations: 200) { arrayIndicesContains() }
report(label: safeLabel, nsPerOp: arraySafeNs)
report(label: containsLabel, nsPerOp: arrayContainsNs)
speedup(safe: arraySafeNs, baseline: arrayContainsNs)

print("String  (n=\(string().count), probes=\(stringIndices().count), BidirectionalCollection / String.Index)")
let stringSafeNs = measure(iterations: 200) { stringSafe() }
let stringContainsNs = measure(iterations: 200) { stringIndicesContains() }
report(label: safeLabel, nsPerOp: stringSafeNs)
report(label: containsLabel, nsPerOp: stringContainsNs)
speedup(safe: stringSafeNs, baseline: stringContainsNs)

print("Dictionary<Int, Int>  (n=\(dict().count), probes=\(dictIndices().count), Collection / opaque Index)")
let dictSafeNs = measure(iterations: 50) { dictionarySafe() }
let dictContainsNs = measure(iterations: 50) { dictionaryIndicesContains() }
report(label: safeLabel, nsPerOp: dictSafeNs)
report(label: containsLabel, nsPerOp: dictContainsNs)
speedup(safe: dictSafeNs, baseline: dictContainsNs)
