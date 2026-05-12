import Testing
@testable import SafeSubscript

@Suite
struct CollectionSafeSubscriptTests {
	@Test func arrayValidIndicesReturnElement() {
		let array = [10, 20, 30]
		#expect(array[safe: 0] == 10)
		#expect(array[safe: 1] == 20)
		#expect(array[safe: 2] == 30)
	}

	@Test func arrayNegativeIndexReturnsNil() {
		let array = [10, 20, 30]
		#expect(array[safe: -1] == nil)
		#expect(array[safe: -100] == nil)
	}

	@Test func arrayOutOfBoundsIndexReturnsNil() {
		let array = [10, 20, 30]
		#expect(array[safe: 3] == nil)
		#expect(array[safe: Int.max] == nil)
	}

	@Test func emptyArrayReturnsNilForAnyIndex() {
		let array: [Int] = []
		#expect(array[safe: 0] == nil)
		#expect(array[safe: -1] == nil)
		#expect(array[safe: 1] == nil)
	}

	@Test(arguments: [
		(0, "a"),
		(1, "b"),
		(2, "c"),
		(3, nil),
		(-1, nil),
	] as [(Int, String?)])
	func arrayParameterized(index: Int, expected: String?) {
		let array = ["a", "b", "c"]
		#expect(array[safe: index] == expected)
	}

	@Test func arraySliceRespectsSliceBounds() {
		let array = [0, 1, 2, 3, 4]
		let slice = array[2...]
		#expect(slice.startIndex == 2)
		#expect(slice.endIndex == 5)

		#expect(slice[safe: 2] == 2)
		#expect(slice[safe: 4] == 4)

		// Inside the original array but outside the slice.
		#expect(slice[safe: 0] == nil)
		#expect(slice[safe: 1] == nil)

		// Beyond endIndex.
		#expect(slice[safe: 5] == nil)
	}

	@Test func contiguousArray() {
		let array: ContiguousArray = [100, 200, 300]
		#expect(array[safe: 0] == 100)
		#expect(array[safe: 2] == 300)
		#expect(array[safe: 3] == nil)
		#expect(array[safe: -1] == nil)
	}

	@Test func stringValidIndices() throws {
		let s = "hello"
		let first = s.startIndex
		let second = s.index(after: first)
		#expect(s[safe: first] == "h")
		#expect(s[safe: second] == "e")
	}

	@Test func stringEndIndexReturnsNil() {
		let s = "hello"
		#expect(s[safe: s.endIndex] == nil)
	}

	@Test func emptyStringReturnsNil() {
		let s = ""
		#expect(s[safe: s.startIndex] == nil)
		#expect(s[safe: s.endIndex] == nil)
	}

	@Test func substringRespectsBounds() throws {
		let s = "hello world"
		let space = try #require(s.firstIndex(of: " "))
		let world = s[s.index(after: space)...]
		#expect(world[safe: world.startIndex] == "w")
		#expect(world[safe: world.endIndex] == nil)
		// Indices before the substring's startIndex are out of bounds.
		#expect(world[safe: s.startIndex] == nil)
	}

	@Test func set() throws {
		let set: Set<Int> = [1, 2, 3]
		let first = try #require(set[safe: set.startIndex])
		#expect(set.contains(first))
		#expect(set[safe: set.endIndex] == nil)
	}

	@Test func emptySet() {
		let set: Set<Int> = []
		#expect(set[safe: set.startIndex] == nil)
		#expect(set[safe: set.endIndex] == nil)
	}

	@Test func dictionary() throws {
		let dict = ["a": 1, "b": 2, "c": 3]
		let entry = try #require(dict[safe: dict.startIndex])
		#expect(dict[entry.key] == entry.value)
		#expect(dict[safe: dict.endIndex] == nil)
	}

	@Test func emptyDictionary() {
		let dict: [String: Int] = [:]
		#expect(dict[safe: dict.startIndex] == nil)
		#expect(dict[safe: dict.endIndex] == nil)
	}

	@Test func range() {
		let range = 10..<15
		#expect(range[safe: 10] == 10)
		#expect(range[safe: 14] == 14)
		#expect(range[safe: 15] == nil)
		#expect(range[safe: 9] == nil)
	}

	@Test func repeatedCollection() {
		let repeated = repeatElement("x", count: 3)
		#expect(repeated[safe: 0] == "x")
		#expect(repeated[safe: 2] == "x")
		#expect(repeated[safe: 3] == nil)
	}

	@Test func lazyCollection() {
		let lazyMapped = [1, 2, 3].lazy.map { $0 * 10 }
		#expect(lazyMapped[safe: 0] == 10)
		#expect(lazyMapped[safe: 2] == 30)
		#expect(lazyMapped[safe: 3] == nil)
	}

	@Test func extremeIndicesDoNotTrap() {
		let array = [1, 2, 3]
		#expect(array[safe: Int.min] == nil)
		#expect(array[safe: Int.max] == nil)
	}
}
