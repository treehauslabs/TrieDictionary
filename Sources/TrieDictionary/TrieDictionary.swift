import Foundation

/**
 A high-performance compressed trie (prefix tree) implementation that provides Dictionary-like
 functionality with advanced path-based operations.
 
 A TrieDictionary stores key-value pairs where keys are strings, using a compressed trie structure
 that minimizes memory usage by merging chains of single-child nodes. This makes it particularly
 efficient for datasets with common prefixes.
 
 ## Key Features:
 - **Memory Efficient**: Path compression reduces memory overhead
 - **Fast Operations**: O(k) lookup, insertion, and deletion where k = key length
 - **Advanced Traversal**: Built-in support for prefix-based operations
 - **Functional Operations**: Methods for transforming keys with prefixes/suffixes
 - **High Performance**: Optimized for speed with method inlining and efficient data structures
 
 ## Usage:
 ```swift
 var trie = TrieDictionary<String>()
 trie["apple"] = "fruit"
 trie["application"] = "software"
 trie["apply"] = "action"
 
 // Traverse by prefix
 let appTrie = trie.traverse("app")
 
 // Get values along a path
 let values = trie.getValuesAlongPath("application")
 ```
 
 ## Performance Characteristics:
 - **Insertion**: O(k) where k is the key length
 - **Lookup**: O(k) where k is the key length
 - **Deletion**: O(k) where k is the key length
 - **Memory**: O(n*m) where n is number of keys, m is average unique prefix length
 
 - Note: Path compression significantly reduces memory usage for datasets with common prefixes
 */
public struct TrieDictionary<Value>: Sendable where Value: Sendable {
    /// The root children array containing the compressed trie structure
    private var children: CompressedChildArray<Value>
    private var value: Value?
    
    /**
     Creates an empty TrieDictionary.
     
     - Complexity: O(1)
     */
    public init() {
        self.children = CompressedChildArray()
    }
    
    /**
     Internal initializer for creating a TrieDictionary with existing children.
     Used for efficient subtrie operations.
     
     - Parameter children: The compressed child array to use as the root
     */
    init(_ children: CompressedChildArray<Value>) {
        self.children = children
        self.value = nil
    }
    
    /**
     Internal initializer for creating a TrieDictionary with both children and a value.
     Used for efficient subtrie operations that need to preserve root values.
     
     - Parameter children: The compressed child array to use as the root
     - Parameter value: The value to store at the root, if any
     */
    init(_ children: CompressedChildArray<Value>, value: Value?) {
        self.children = children
        self.value = value
    }
    
    /**
     Returns `true` if the trie contains no key-value pairs.
     
     - Complexity: O(1)
     */
    @inline(__always)
    public var isEmpty: Bool {
        children.isEmpty && value == nil
    }
    
    /**
     The number of key-value pairs stored in the trie.
     
     - Complexity: O(n) where n is the number of nodes in the trie
     - Note: This traverses the entire trie structure to count values
     */
    public var count: Int {
        return children.totalCount + (value == nil ? 0 : 1)
    }
    
    /**
     Accesses the value associated with the given key for reading and writing.
     
     Use this subscript to retrieve values from the trie or to add, update, or remove values:
     
     ```swift
     var trie = TrieDictionary<String>()
     trie["hello"] = "world"      // Insert
     print(trie["hello"])         // Retrieve: Optional("world")
     trie["hello"] = "universe"   // Update
     trie["hello"] = nil          // Remove
     ```
     
     - Parameter key: The string key to look up or modify
     - Returns: The value associated with the key, or `nil` if no value exists
     - Complexity: O(k) where k is the length of the key
     */
    public subscript(key: String) -> Value? {
        get {
            if key == "" { return value }
            guard let firstChar = key.first else { return nil }
            guard let child = children.child(for: firstChar) else { return nil }
            return child.value(for: key)
        }
        set {
            if key == "" {
                self.value = newValue
                return
            }
            guard let firstChar = key.first else { return }
            if let newValue = newValue {
                if let existingChild = children.child(for: firstChar) {
                    let updatedChild = existingChild.setting(key: key, value: newValue)
                    children = children.setting(char: firstChar, node: updatedChild)
                } else {
                    let newChild = TrieNode(value: newValue, children: CompressedChildArray(), compressedPath: key)
                    children = children.setting(char: firstChar, node: newChild)
                }
            }
            else {
                if let existingChild = children.child(for: firstChar) {
                    if let updatedChild = existingChild.removing(key: key) {
                        children = children.setting(char: firstChar, node: updatedChild)
                    } else {
                        children = children.removing(char: firstChar)
                    }
                }
            }
        }
    }
    
    /**
     Returns an array containing all keys in the trie.
     
     The order of keys in the returned array is determined by the trie's internal structure
     and may not be alphabetically sorted.
     
     ```swift
     var trie = TrieDictionary<Int>()
     trie["apple"] = 1
     trie["banana"] = 2
     let allKeys = trie.keys() // ["apple", "banana"]
     ```
     
     - Returns: An array of all keys in the trie
     - Complexity: O(n*m) where n is the number of keys and m is the average key length
     */
    public func keys() -> [String] {
        var keys: [String] = []
        if value != nil { keys.append("") }
        children.forEach { node in
            let childKeys = node.allKeys()
            for childKey in childKeys {
                keys.append(childKey)
            }
        }
        return keys
    }
    
    /**
     Returns an array containing all values in the trie.
     
     The order of values corresponds to the order of their associated keys as returned by `keys()`.
     
     ```swift
     var trie = TrieDictionary<String>()
     trie["apple"] = "red"
     trie["banana"] = "yellow"
     let allValues = trie.values() // ["red", "yellow"]
     ```
     
     - Returns: An array of all values in the trie
     - Complexity: O(n) where n is the number of key-value pairs
     */
    public func values() -> [Value] {
        var values: [Value] = []
        if value != nil { values.append(value!) }
        children.forEach { node in
            let childValues = node.allValues()
            values.append(contentsOf: childValues)
        }
        return values
    }
    
    /**
     Returns a new TrieDictionary containing all key-value pairs whose keys start with the given prefix.
     
     This creates a subtrie rooted at the end of the prefix path. Keys in the returned trie
     will have the prefix removed. If there is a value at the end of the prefix path, it will
     be set as the root value of the new TrieDictionary.
     
     ```swift
     var trie = TrieDictionary<String>()
     trie["apple"] = "fruit"
     trie["application"] = "software"
     trie["apply"] = "action"
     
     let appTrie = trie.traverse("app")
     // appTrie contains: "le" -> "fruit", "lication" -> "software", "ly" -> "action"
     ```
     
     - Parameter prefix: The prefix to search for
     - Returns: A new TrieDictionary containing matching key-value pairs with prefix removed
     - Complexity: O(k) where k is the length of the prefix
     */
    public func traverse(_ prefix: String) -> TrieDictionary<Value> {
        guard let firstChar = prefix.first else { return self }
        guard let child = children.child(for: firstChar) else { return Self() }
        let (childrenArray, rootValue) = child.traverse(prefix: prefix)
        return Self(childrenArray, value: rootValue)
    }
    
    
    /**
     Returns an array of all values found along the path from root to the given key.
     
     This method collects values from all nodes encountered while traversing the path,
     not just the final destination. Useful for hierarchical data structures.
     
     ```swift
     var trie = TrieDictionary<String>()
     trie["a"] = "first"
     trie["app"] = "second"
     trie["apple"] = "third"
     
     let values = trie.getValuesAlongPath("apple")
     // values = ["first", "second", "third"]
     ```
     
     - Parameter path: The path to traverse
     - Returns: An array of values encountered along the path
     - Complexity: O(k) where k is the length of the path
     */
    public func getValuesAlongPath(_ path: String) -> [Value] {
        guard let firstChar = path.first else { return [] }
        guard let child = children.child(for: firstChar) else { return [] }
        if let value = value {
            return [value] + child.getValuesAlongPath(path: path)
        }
        return child.getValuesAlongPath(path: path)
    }
    
    /**
     Updates the value stored in the trie for the given key, or adds a new key-value pair if the key doesn't exist.
     
     ```swift
     var trie = TrieDictionary<String>()
     let oldValue = trie.updateValue("world", forKey: "hello") // nil
     let previousValue = trie.updateValue("universe", forKey: "hello") // "world"
     ```
     
     - Parameter value: The value to associate with the key
     - Parameter key: The key to update
     - Returns: The previous value associated with the key, or `nil` if the key was not present
     - Complexity: O(k) where k is the length of the key
     */
    @discardableResult
    public mutating func updateValue(_ value: Value, forKey key: String) -> Value? {
        let oldValue = self[key]
        self[key] = value
        return oldValue
    }
    
    /**
     Removes the value for the given key and returns the removed value, or `nil` if the key was not present.
     
     ```swift
     var trie = TrieDictionary<String>()
     trie["hello"] = "world"
     let removed = trie.removeValue(forKey: "hello") // "world"
     let notFound = trie.removeValue(forKey: "missing") // nil
     ```
     
     - Parameter key: The key to remove
     - Returns: The value that was removed, or `nil` if the key was not present
     - Complexity: O(k) where k is the length of the key
     */
    @discardableResult
    public mutating func removeValue(forKey key: String) -> Value? {
        let oldValue = self[key]
        self[key] = nil
        return oldValue
    }
    
    /**
     Removes all key-value pairs from the trie.
     
     ```swift
     var trie = TrieDictionary<String>()
     trie["key1"] = "value1"
     trie["key2"] = "value2"
     trie.removeAll()
     print(trie.isEmpty) // true
     ```
     
     - Complexity: O(1)
     */
    public mutating func removeAll() {
        children = CompressedChildArray()
        value = nil
    }
    
    // MARK: - Functional Traverse and Path Operations
    
    /**
     Returns a new TrieDictionary where all keys are prefixed with the given string.
     
     This creates a new trie where every key from the original trie is prefixed with the
     specified string. The original trie remains unchanged.
     
     ```swift
     var trie = TrieDictionary<String>()
     trie["apple"] = "fruit"
     trie["tree"] = "plant"
     
     let prefixed = trie.addingPrefix("my_")
     // prefixed contains: "my_apple" -> "fruit", "my_tree" -> "plant"
     ```
     
     - Parameter prefix: The string to prepend to all keys
     - Returns: A new TrieDictionary with prefixed keys
     - Complexity: O(n*m) where n is the number of keys and m is the average key length
     */
    public func addingPrefix(_ prefix: String) -> TrieDictionary<Value> {
        if prefix.isEmpty || isEmpty { return self }
        if value != nil || children.childCount > 1 {
            let newChild = TrieNode(value: value, children: children, compressedPath: prefix)
            let newChildren = CompressedChildArray().setting(char: prefix.first!, node: newChild)
            return Self(newChildren)
        }
        let oldChild = children.firstChild!
        let newChild = TrieNode(value: oldChild.value, children: oldChild.children, compressedPath: prefix + oldChild.compressedPath)
        let newChildren = CompressedChildArray().setting(char: prefix.first!, node: newChild)
        return Self(newChildren)
    }

    /**
     Returns a TrieDictionary mapping paths to arrays of values found along each path.
     
     For each path in the input array, this method collects all values encountered while
     traversing from the root to that path, similar to `getValuesAlongPath` but for multiple paths.
     
     ```swift
     var trie = TrieDictionary<String>()
     trie["a"] = "first"
     trie["app"] = "second"
     trie["apple"] = "third"
     
     let gathered = trie.gatheringValuesAlongPaths(["apple", "app"])
     // gathered contains: "apple" -> ["first", "second", "third"], "app" -> ["first", "second"]
     ```
     
     - Parameter paths: An array of paths to traverse
     - Returns: A TrieDictionary mapping each path to its collected values
     - Complexity: O(p*k) where p is the number of paths and k is the average path length
     */
    public func gatheringValuesAlongPaths(_ paths: [String]) -> TrieDictionary<[Value]> {
        var result = TrieDictionary<[Value]>()
        for path in paths {
            let values = getValuesAlongPath(path)
            if !values.isEmpty {
                result[path] = values
            }
        }
        return result
    }
    
    public func traverseChild(_ char: Character) -> Self? {
        guard let child = children.child(for: char) else { return nil }
        return Self(CompressedChildArray().setting(char: char, node: child), value: value)
    }
    
    public func traverseToNextChild(_ char: Character) -> (String, Self)? {
        guard let child = children.child(for: char) else { return nil }
        return (child.compressedPath, Self(child.children, value: child.value))
    }
    
    public func getChildPrefix(_ char: Character) -> String? {
        guard let child = children.child(for: char) else { return nil }
        return child.compressedPath
    }
    
    /**
     Returns a new TrieDictionary containing only the subtrie at the given prefix.
     
     This is equivalent to `traverse(_:)` and creates a subtrie rooted at the end of the prefix path.
     Keys in the returned trie will have the prefix removed.
     
     ```swift
     var trie = TrieDictionary<String>()
     trie["prefix_apple"] = "fruit"
     trie["prefix_tree"] = "plant"
     trie["other"] = "item"
     
     let sub = trie.subtrie(at: "prefix_")
     // sub contains: "apple" -> "fruit", "tree" -> "plant"
     ```
     
     - Parameter prefix: The prefix to use as the root of the subtrie
     - Returns: A new TrieDictionary containing the subtrie
     - Complexity: O(k) where k is the length of the prefix
     */
    public func subtrie(at prefix: String) -> TrieDictionary<Value> {
        return traverse(prefix)
    }
    
    /**
     Returns a new TrieDictionary containing the merged contents of this trie and another.
     
     When both tries contain values for the same key, the merge rule determines the result.
     Keys that exist in only one trie are preserved in the merged result.
     
     ```swift
     var trie1 = TrieDictionary<Int>()
     trie1["apple"] = 1
     trie1["banana"] = 2
     
     var trie2 = TrieDictionary<Int>()
     trie2["apple"] = 10
     trie2["cherry"] = 3
     
     let merged = trie1.merging(other: trie2, uniquingKeysWith: { value1, value2 in
         return value1 + value2  // Sum conflicting values
     })
     // merged contains: "apple" -> 11, "banana" -> 2, "cherry" -> 3
     ```
     
     - Parameter other: The other TrieDictionary to merge with
     - Parameter combine: A closure that resolves conflicts when both tries have values for the same key
     - Returns: A new TrieDictionary containing the merged result
     - Complexity: O(m + n) where m and n are the sizes of the two tries
     */
    public func merging(other: Self, uniquingKeysWith combine: (Value, Value) -> Value) -> Self {
        // Handle trivial cases
        if isEmpty { return other }
        if other.isEmpty { return self }
        
        // Merge root values
        let mergedRootValue: Value?
        if let selfValue = value, let otherValue = other.value {
            mergedRootValue = combine(selfValue, otherValue)
        } else {
            mergedRootValue = value ?? other.value
        }
        
        // Merge children using the CompressedChildArray merge method
        let mergedChildren = children.merging(with: other.children) { selfNode, otherNode in
            return selfNode.merging(with: otherNode, mergeRule: combine)
        }
        
        return Self(mergedChildren, value: mergedRootValue)
    }
    
    // MARK: - Structural Transformation

    public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> TrieDictionary<T> {
        let newValue = try value.map(transform)
        let newChildren = try children.mapValues(transform)
        return TrieDictionary<T>(newChildren, value: newValue)
    }

    public func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> TrieDictionary<T> {
        let newValue = try value.flatMap { try transform($0) }
        let newChildren = try children.compactMapValues(transform)
        return TrieDictionary<T>(newChildren, value: newValue)
    }

    // MARK: - Pair Collection (for iteration)

    internal func collectAllPairs() -> [(key: String, value: Value)] {
        var pairs: [(key: String, value: Value)] = []
        if let v = value { pairs.append((key: "", value: v)) }
        children.forEach { node in
            node.collectPairs(prefix: "", into: &pairs)
        }
        return pairs
    }

}

// MARK: - Testing Support
extension TrieDictionary {
    /**
     Returns `true` if the trie is in a fully compressed state.
     
     A fully compressed trie satisfies these invariants:
     - No node has exactly one child with no value (such nodes should be merged)
     - No node has no children and no value (except for empty tries)
     
     This property is primarily used for testing and debugging to ensure the trie
     maintains its compressed structure after operations.
     
     - Returns: `true` if the trie structure is properly compressed
     - Complexity: O(n) where n is the number of nodes
     */
    public var isFullyCompressed: Bool {
        var allChildrenCompressed = true
        children.forEach { childNode in
            if !childNode.isFullyCompressed {
                allChildrenCompressed = false
            }
        }
        return allChildrenCompressed
    }
    
    /**
     Returns an array of all characters that have child nodes at the root level.
     
     This method efficiently retrieves characters directly from the CompressedChildArray
     without needing to traverse the trie structure.
     
     - Returns: An array of characters representing the first character of all keys
     - Complexity: O(n) where n is the number of direct child nodes
     */
    public func getAllChildCharacters() -> [Character] {
        return children.allChildCharacters
    }
}
