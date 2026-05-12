import Testing
@testable import SafeSubscript

@Suite
struct MutableCollectionSafeSubscriptTests {
	@Test func setWithinBoundsUpdatesElement() {
		var array = [1, 2, 3]
		array[safe: 1] = 20
		#expect(array == [1, 20, 3])
	}

	@Test func setOutOfBoundsIsNoOp() {
		var array = [1, 2, 3]
		array[safe: 10] = 99
		array[safe: -1] = 99
		array[safe: 3] = 99
		array[safe: Int.max] = 99
		#expect(array == [1, 2, 3])
	}

	@Test func setOnEmptyCollectionIsNoOp() {
		var array: [Int] = []
		array[safe: 0] = 1
		array[safe: -1] = 1
		#expect(array.isEmpty)
	}

	@Test func setNilDoesNotMutate() {
		var array = [1, 2, 3]
		array[safe: 1] = nil
		#expect(array == [1, 2, 3])
	}

	@Test func setOnContiguousArray() {
		var array: ContiguousArray = [1, 2, 3]
		array[safe: 0] = 10
		array[safe: 5] = 99
		#expect(Array(array) == [10, 2, 3])
	}

	@Test func setOnArraySliceRespectsSliceBounds() {
		let array = [0, 1, 2, 3, 4]
		var slice = array[2...]

		slice[safe: 2] = 200
		#expect(slice[2] == 200)

		// Outside the slice — must be a no-op.
		slice[safe: 0] = 1000
		slice[safe: 5] = 1000
		#expect(slice[2] == 200)
		#expect(Array(slice) == [200, 3, 4])
	}

	@Test(arguments: [
		(0, 99, [99, 2, 3]),
		(1, 99, [1, 99, 3]),
		(2, 99, [1, 2, 99]),
		(3, 99, [1, 2, 3]),
		(-1, 99, [1, 2, 3]),
	])
	func setParameterized(index: Int, value: Int, expected: [Int]) {
		var array = [1, 2, 3]
		array[safe: index] = value
		#expect(array == expected)
	}
}
