import Foundation

/**
 Internal node structure for the compressed trie implementation.

 Each TrieNode represents a compressed path in the trie, containing:
 - An optional value (if this node represents the end of a key)
 - A compressed path string (representing a chain of characters)
 - Child nodes for continuing the trie structure

 ## Path Compression:
 Instead of storing single characters at each level, nodes store entire path segments.
 For example, if "application" is the only word starting with "app", the node will
 store "application" as a compressed path rather than creating separate nodes for
 "a", "p", "p", "l", "i", "c", "a", "t", "i", "o", "n".

 ## Performance Optimizations:
 - Method inlining for hot paths
 - Zero-allocation path comparison via direct String index walking
 - Efficient path splitting and merging algorithms
 */
internal struct TrieNode<Value>: Sendable where Value: Sendable {
    let value: Value?
    let children: CompressedChildArray<Value>
    let compressedPath: String

    /**
     Creates an empty node with no value, children, or compressed path.
     */
    init() {
        self.value = nil
        self.children = CompressedChildArray()
        self.compressedPath = ""
    }

    /**
     Creates a node with only a compressed path and no value or children.

     - Parameter compressedPath: The path segment to store at this node
     */
    init(compressedPath: String) {
        self.value = nil
        self.children = CompressedChildArray()
        self.compressedPath = compressedPath
    }

    /**
     Creates a node with the specified value, children, and compressed path.

     - Parameter value: The value to store at this node (nil if no value)
     - Parameter children: The child nodes
     - Parameter compressedPath: The compressed path segment
     */
    init(value: Value?, children: CompressedChildArray<Value>, compressedPath: String = "") {
        self.value = value
        self.children = children
        self.compressedPath = compressedPath
    }

    /**
     Returns `true` if this node has no value and no children.

     - Complexity: O(1)
     */
    @inline(__always)
    var isEmpty: Bool {
        value == nil && children.isEmpty
    }


    /**
     Returns the total number of values stored in this subtree.

     This includes the value at this node (if any) plus all values in child nodes.

     - Returns: The total count of values in this subtree
     - Complexity: O(n) where n is the number of nodes in the subtree
     */
    var count: Int {
        let selfCount = value != nil ? 1 : 0
        return selfCount + children.totalCount
    }

    // MARK: - Zero-Allocation Path Matching

    /**
     Walks an ArraySlice<Character> key against this node's compressedPath String
     simultaneously, returning the indices where they first diverge.

     No heap allocation occurs — this compares Character values via String.Index
     iteration against the ArraySlice's random-access indices.

     - Complexity: O(min(key.count, compressedPath.count))
     */
    @inline(__always)
    private func matchKeyToPath(_ key: ArraySlice<Character>) -> (keyIdx: ArraySlice<Character>.Index, pathIdx: String.Index) {
        var keyIdx = key.startIndex
        var pathIdx = compressedPath.startIndex
        while keyIdx < key.endIndex && pathIdx < compressedPath.endIndex {
            if key[keyIdx] != compressedPath[pathIdx] { break }
            key.formIndex(after: &keyIdx)
            compressedPath.formIndex(after: &pathIdx)
        }
        return (keyIdx, pathIdx)
    }

    /**
     Walks two String paths simultaneously, returning the indices where they first diverge.
     Used by the merge operation to compare two nodes' compressed paths.

     - Complexity: O(min(path1.count, path2.count))
     */
    @inline(__always)
    private func matchTwoPaths(_ path1: String, _ path2: String) -> (idx1: String.Index, idx2: String.Index) {
        var idx1 = path1.startIndex
        var idx2 = path2.startIndex
        while idx1 < path1.endIndex && idx2 < path2.endIndex {
            if path1[idx1] != path2[idx2] { break }
            path1.formIndex(after: &idx1)
            path2.formIndex(after: &idx2)
        }
        return (idx1, idx2)
    }

    // MARK: - Lookup

    /**
     Retrieves the value associated with the given key in this subtree.

     - Parameter key: The key to search for
     - Returns: The associated value, or `nil` if not found
     - Complexity: O(k) where k is the length of the key
     */
    func value(for key: String) -> Value? {
        return value(for: ArraySlice(key))
    }

    private func value(for key: ArraySlice<Character>) -> Value? {
        let (keyIdx, pathIdx) = matchKeyToPath(key)

        if pathIdx < compressedPath.endIndex {
            return nil
        }
        // compressedPath fully consumed
        if keyIdx == key.endIndex {
            return value
        }
        // Key continues — descend into children
        guard let child = children.child(for: key[keyIdx]) else { return nil }
        return child.value(for: key[keyIdx...])
    }

    // MARK: - Insertion

    /**
     Returns a new node with the given key-value pair added or updated.

     This method implements path compression by potentially splitting nodes
     when new keys diverge from existing compressed paths.

     - Parameter key: The key to add or update
     - Parameter value: The value to associate with the key
     - Returns: A new TrieNode representing the updated subtree
     - Complexity: O(k) where k is the length of the key
     */
    func setting(key: String, value: Value) -> TrieNode<Value> {
        return setting(key: ArraySlice(key), value: value)
    }

    private func setting(key: ArraySlice<Character>, value: Value) -> TrieNode<Value> {
        if key.isEmpty {
            return TrieNode(value: value, children: children, compressedPath: compressedPath)
        }

        let (keyIdx, pathIdx) = matchKeyToPath(key)
        let keyDone = keyIdx == key.endIndex
        let pathDone = pathIdx == compressedPath.endIndex

        if keyDone && pathDone {
            return TrieNode(value: value, children: children, compressedPath: compressedPath)
        }
        if pathDone {
            let childChar = key[keyIdx]
            let newKey = key[keyIdx...]
            if let child = children.child(for: childChar) {
                let updatedChild = child.setting(key: newKey, value: value)
                let newChildren = children.setting(char: childChar, node: updatedChild)
                return TrieNode(value: self.value, children: newChildren, compressedPath: compressedPath)
            } else {
                let newChild = TrieNode(value: value, children: CompressedChildArray(), compressedPath: String(newKey))
                let newChildren = children.setting(char: childChar, node: newChild)
                return TrieNode(value: self.value, children: newChildren, compressedPath: compressedPath)
            }
        }
        if keyDone {
            let remainingPath = String(compressedPath[pathIdx...])
            let existingChild = TrieNode(value: self.value, children: children, compressedPath: remainingPath)
            let newChildren = CompressedChildArray<Value>().setting(char: remainingPath.first!, node: existingChild)
            return TrieNode(value: value, children: newChildren, compressedPath: String(key))
        }
        // Paths diverge — split at the common prefix
        let commonPrefix = String(compressedPath[compressedPath.startIndex..<pathIdx])
        let keyRemainder = String(key[keyIdx...])
        let pathRemainder = String(compressedPath[pathIdx...])

        let existingChild = TrieNode(value: self.value, children: children, compressedPath: pathRemainder)
        var newChildren = CompressedChildArray<Value>().setting(char: pathRemainder.first!, node: existingChild)

        let newChild = TrieNode(value: value, children: CompressedChildArray(), compressedPath: keyRemainder)
        newChildren = newChildren.setting(char: keyRemainder.first!, node: newChild)
        return TrieNode(value: nil, children: newChildren, compressedPath: commonPrefix)
    }

    // MARK: - Removal

    /**
     Returns a new node with the given key removed, or `nil` if the node becomes empty.

     This method handles path compression by potentially merging nodes when
     a removal operation leaves a node with only one child and no value.

     - Parameter key: The key to remove
     - Returns: A new TrieNode without the key, or `nil` if the subtree becomes empty
     - Complexity: O(k) where k is the length of the key
     */
    func removing(key: String) -> TrieNode<Value>? {
        return removing(keySlice: ArraySlice(key))
    }

    private func removing(keySlice: ArraySlice<Character>) -> TrieNode<Value>? {
        let (keyIdx, pathIdx) = matchKeyToPath(keySlice)
        let keyDone = keyIdx == keySlice.endIndex
        let pathDone = pathIdx == compressedPath.endIndex

        if keyDone && pathDone {
            if children.childCount == 0 {
                return nil
            }
            if children.childCount == 1 {
                let child = children.firstChild!
                return Self(value: child.value, children: child.children, compressedPath: compressedPath + child.compressedPath)
            }
            return Self(value: nil, children: children, compressedPath: compressedPath)
        }
        if pathDone {
            let childChar = keySlice[keyIdx]
            guard let child = children.child(for: childChar) else { return self }
            let newChild = child.removing(keySlice: keySlice[keyIdx...])
            if let newChild = newChild {
                let newChildren = children.setting(char: childChar, node: newChild)
                return Self(value: value, children: newChildren, compressedPath: compressedPath)
            }
            let newChildren = children.removing(char: childChar)
            if newChildren.childCount == 0 && value == nil {
                return nil
            }
            if newChildren.childCount == 1 && value == nil {
                let child = newChildren.firstChild!
                return Self(value: child.value, children: child.children, compressedPath: compressedPath + child.compressedPath)
            }
            return Self(value: value, children: newChildren, compressedPath: compressedPath)
        }
        return self
    }

    // MARK: - Structural Transformation

    func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> TrieNode<T> {
        let newValue = try value.map(transform)
        let newChildren = try children.mapValues(transform)
        return TrieNode<T>(value: newValue, children: newChildren, compressedPath: compressedPath)
    }

    func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> TrieNode<T>? {
        let newValue = try value.flatMap { try transform($0) }
        let newChildren = try children.compactMapValues(transform)

        if newValue == nil && newChildren.childCount == 0 {
            return nil
        }
        if newValue == nil && newChildren.childCount == 1 {
            let child = newChildren.firstChild!
            return TrieNode<T>(value: child.value, children: child.children, compressedPath: compressedPath + child.compressedPath)
        }
        return TrieNode<T>(value: newValue, children: newChildren, compressedPath: compressedPath)
    }

    // MARK: - Key/Value Collection

    func collectPairs(prefix: String, into pairs: inout [(key: String, value: Value)]) {
        let fullPrefix = prefix + compressedPath
        if let v = value {
            pairs.append((key: fullPrefix, value: v))
        }
        children.forEach { node in
            node.collectPairs(prefix: fullPrefix, into: &pairs)
        }
    }

    /**
     Returns all keys stored in this subtree.

     The keys are collected by traversing the entire subtree and building
     complete key strings from the compressed path segments.

     - Returns: An array of all keys in this subtree
     - Complexity: O(n*m) where n is the number of keys and m is the average key length
     */
    func allKeys() -> [String] {
        var keys: [String] = []
        collectKeys(prefix: "", into: &keys)
        return keys
    }

    /**
     Returns all values stored in this subtree.

     - Returns: An array of all values in this subtree
     - Complexity: O(n) where n is the number of values
     */
    func allValues() -> [Value] {
        var values: [Value] = []
        collectValues(into: &values)
        return values
    }

    private func collectKeys(prefix: String, into keys: inout [String]) {
        let fullPrefix = prefix + compressedPath

        if value != nil {
            keys.append(fullPrefix)
        }

        children.forEach { node in
            node.collectKeys(prefix: fullPrefix, into: &keys)
        }
    }

    private func collectValues(into values: inout [Value]) {
        if let value = value {
            values.append(value)
        }

        children.forEach { node in
            node.collectValues(into: &values)
        }
    }

    // MARK: - Traversal

    /**
     Returns the compressed child array and value representing the subtree at the given prefix.

     This method navigates to the end of the prefix path and returns both the child array
     and any value from that point, effectively creating a subtrie rooted at the prefix.

     - Parameter prefix: The prefix to traverse to
     - Returns: A tuple containing the compressed child array and optional value at the prefix location
     - Complexity: O(k) where k is the length of the prefix
     */
    func traverse(prefix: String) -> (CompressedChildArray<Value>, Value?) {
        return traverse(prefix: ArraySlice(prefix))
    }

    private func traverse(prefix: ArraySlice<Character>) -> (CompressedChildArray<Value>, Value?) {
        let (keyIdx, pathIdx) = matchKeyToPath(prefix)
        let prefixDone = keyIdx == prefix.endIndex
        let pathDone = pathIdx == compressedPath.endIndex

        if prefixDone && pathDone {
            return (children, value)
        }
        if pathDone {
            guard let childNode = children.child(for: prefix[keyIdx]) else {
                return (CompressedChildArray(), nil)
            }
            return childNode.traverse(prefix: prefix[keyIdx...])
        }
        if prefixDone {
            let remainingPath = String(compressedPath[pathIdx...])
            return (CompressedChildArray().setting(char: remainingPath.first!, node: TrieNode(value: value, children: children, compressedPath: remainingPath)), nil)
        }
        return (CompressedChildArray(), nil)
    }

    // MARK: - Path Value Collection

    /**
     Returns all values encountered while traversing the given path.

     This method collects values from all nodes visited during path traversal,
     not just the final destination. Useful for hierarchical data access.

     - Parameter path: The path to traverse
     - Returns: An array of values found along the path
     - Complexity: O(k) where k is the length of the path
     */
    func getValuesAlongPath(path: String) -> [Value] {
        var values: [Value] = []
        getValuesAlongPath(path: ArraySlice(path), values: &values)
        return values
    }

    private func getValuesAlongPath(path: ArraySlice<Character>, values: inout [Value]) {
        let (keyIdx, pathIdx) = matchKeyToPath(path)
        let keyDone = keyIdx == path.endIndex
        let pathDone = pathIdx == compressedPath.endIndex

        if keyDone && pathDone {
            if let v = value { values.append(v) }
            return
        }
        if pathDone {
            if let v = value { values.append(v) }
            guard let childNode = children.child(for: path[keyIdx]) else { return }
            childNode.getValuesAlongPath(path: path[keyIdx...], values: &values)
        }
    }

    // MARK: - Merge

    /**
     Returns a new node that merges this node with another node.

     This method handles merging of compressed paths, values, and child nodes.
     When both nodes have values, the merge rule determines the result.
     When compressed paths differ, they are properly aligned and merged.

     - Parameter other: The other TrieNode to merge with
     - Parameter mergeRule: A closure that resolves conflicts when both nodes have values
     - Returns: A new merged TrieNode
     - Complexity: O(m + n) where m and n are the sizes of the child arrays
     */
    func merging(with other: TrieNode<Value>, mergeRule: (Value, Value) -> Value) -> TrieNode<Value> {
        let (selfIdx, otherIdx) = matchTwoPaths(compressedPath, other.compressedPath)
        let selfDone = selfIdx == compressedPath.endIndex
        let otherDone = otherIdx == other.compressedPath.endIndex

        if selfDone && otherDone {
            let mergedValue = value != nil ? (other.value != nil ? mergeRule(value!, other.value!) : value) : other.value
            return Self(value: mergedValue, children: children.merging(with: other.children, mergeRule: { $0.merging(with: $1, mergeRule: mergeRule) }), compressedPath: compressedPath)
        }
        if otherDone {
            let selfRemainder = String(compressedPath[selfIdx...])
            let selfChar = selfRemainder.first!
            let selfChild = TrieNode(value: value, children: children, compressedPath: selfRemainder)
            if let otherChild = other.children.child(for: selfChar) {
                let newChildren = other.children.setting(char: selfChar, node: selfChild.merging(with: otherChild, mergeRule: mergeRule))
                return Self(value: other.value, children: newChildren, compressedPath: other.compressedPath)
            }
            let newChildren = other.children.setting(char: selfChar, node: selfChild)
            return Self(value: other.value, children: newChildren, compressedPath: other.compressedPath)
        }
        if selfDone {
            let otherRemainder = String(other.compressedPath[otherIdx...])
            let otherChar = otherRemainder.first!
            let otherChild = TrieNode(value: other.value, children: other.children, compressedPath: otherRemainder)
            if let selfChild = children.child(for: otherChar) {
                let newChildren = children.setting(char: otherChar, node: selfChild.merging(with: otherChild, mergeRule: mergeRule))
                return Self(value: value, children: newChildren, compressedPath: compressedPath)
            }
            let newChildren = children.setting(char: otherChar, node: otherChild)
            return Self(value: value, children: newChildren, compressedPath: compressedPath)
        }
        let commonPrefixStr = String(compressedPath[compressedPath.startIndex..<selfIdx])
        let selfRemainder = String(compressedPath[selfIdx...])
        let otherRemainder = String(other.compressedPath[otherIdx...])
        let selfChar = selfRemainder.first!
        let otherChar = otherRemainder.first!
        let newChildren = CompressedChildArray<Value>()
            .setting(char: selfChar, node: Self(value: value, children: children, compressedPath: selfRemainder))
            .setting(char: otherChar, node: Self(value: other.value, children: other.children, compressedPath: otherRemainder))
        return Self(value: nil, children: newChildren, compressedPath: commonPrefixStr)
    }

}

// MARK: - Testing Support
internal extension TrieNode {
    /**
     Returns `true` if this node and all its descendants maintain proper compression invariants.

     A properly compressed node satisfies:
     - If it has no value and exactly one child, it should be merged with that child
     - If it has no value and no children, it should only exist as an empty root

     This property is used for testing and debugging trie compression.

     - Returns: `true` if the subtree is properly compressed
     - Complexity: O(n) where n is the number of nodes in the subtree
     */
    var isFullyCompressed: Bool {
        if value == nil && children.childCount == 1 {
            return false
        }

        if value == nil && children.childCount == 0 && !compressedPath.isEmpty {
            return false
        }

        var allChildrenCompressed = true
        children.forEach { childNode in
            if !childNode.isFullyCompressed {
                allChildrenCompressed = false
            }
        }

        return allChildrenCompressed
    }

}
