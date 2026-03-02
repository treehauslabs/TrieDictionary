import Foundation

/**
 Collection and Sequence conformance for TrieDictionary.
 
 This file implements the Swift Collection and Sequence protocols, enabling TrieDictionary
 to work with for-in loops, higher-order functions like map/filter/reduce, and other
 collection-based operations.
 */

// MARK: - Collection Conformance

/**
 Makes TrieDictionary conform to the Collection protocol.
 
 This enables using TrieDictionary with collection methods and allows iteration
 over key-value pairs. The collection is indexed by integer positions.
 
 **Note**: The Collection implementation is primarily for compatibility with Swift's
 collection algorithms. For performance-critical iterations, prefer using the
 trie-specific methods or direct key-based access.
 */
extension TrieDictionary: Collection {
    /// The element type for collection operations: a tuple of (key, value)
    public typealias Element = (key: String, value: Value)
    
    /// Integer-based indexing for collection conformance
    public typealias Index = Int
    
    /**
     The position of the first element in the collection.
     
     - Returns: Always 0 for non-empty collections
     - Complexity: O(1)
     */
    public var startIndex: Index {
        return 0
    }
    
    /**
     The position one past the last element in the collection.
     
     - Returns: The count of key-value pairs
     - Complexity: O(n) where n is the number of nodes (due to count calculation)
     */
    public var endIndex: Index {
        return count
    }
    
    /**
     Returns the index immediately after the given index.
     
     - Parameter i: The index to advance
     - Returns: The next index
     - Complexity: O(1)
     */
    public func index(after i: Index) -> Index {
        return i + 1
    }
    
    /**
     Accesses the key-value pair at the specified position.
     
     **Warning**: This implementation has O(n*m) complexity due to key collection.
     For better performance, use direct key-based access or iteration methods.
     
     - Parameter position: The position of the element to access
     - Returns: The key-value pair at the specified position
     - Complexity: O(n*m) where n is the number of keys and m is the average key length
     - Precondition: `position` must be a valid index (0 <= position < count)
     */
    public subscript(position: Index) -> Element {
        let keys = self.keys()
        let key = keys[position]
        let value = self[key]!
        return (key: key, value: value)
    }
}

// MARK: - Sequence Conformance

/**
 Makes TrieDictionary conform to the Sequence protocol.
 
 This enables for-in loops and sequence-based operations like map, filter, reduce.
 The iterator provides efficient traversal of all key-value pairs.
 */
extension TrieDictionary: Sequence {
    /**
     Creates an iterator for traversing all key-value pairs.
     
     - Returns: A TrieDictionaryIterator for this trie
     - Complexity: O(n*m) where n is the number of keys and m is the average key length
     */
    public func makeIterator() -> TrieDictionaryIterator<Value> {
        return TrieDictionaryIterator(dictionary: self)
    }
}

// MARK: - Iterator Implementation

/**
 An iterator for traversing TrieDictionary key-value pairs.

 This iterator pre-computes all (key, value) pairs in a single tree traversal,
 avoiding the cost of re-looking up each value by key.
 */
public struct TrieDictionaryIterator<Value>: IteratorProtocol {
    public typealias Element = (key: String, value: Value)

    private let pairs: [(key: String, value: Value)]
    private var currentIndex: Int = 0

    /**
     Creates an iterator for the given TrieDictionary.

     - Parameter dictionary: The TrieDictionary to iterate over
     - Complexity: O(n*m) where n is the number of keys and m is the average key length
     */
    internal init(dictionary: TrieDictionary<Value>) {
        self.pairs = dictionary.collectAllPairs()
    }

    /**
     Advances to the next element and returns it, or returns `nil` if no next element exists.

     - Returns: The next key-value pair, or `nil` if the iteration is complete
     - Complexity: O(1)
     */
    public mutating func next() -> Element? {
        guard currentIndex < pairs.count else { return nil }
        let pair = pairs[currentIndex]
        currentIndex += 1
        return pair
    }
}