extension Collection {
	@inlinable
	public subscript(safe index: Index) -> Element? {
		index >= startIndex && index < endIndex ? self[index] : nil
	}
}

extension MutableCollection {
	@inlinable
	public subscript(safe index: Index) -> Element? {
		get {
			index >= startIndex && index < endIndex ? self[index] : nil
		}
		set {
			if let newValue, index >= startIndex, index < endIndex {
				self[index] = newValue
			}
		}
	}
}
