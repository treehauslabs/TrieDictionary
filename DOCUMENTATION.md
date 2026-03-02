# TrieDictionary API Documentation

Complete API reference for TrieDictionary - a high-performance compressed trie implementation in Swift.

## Table of Contents

- [Core Types](#core-types)
- [Initialization](#initialization)
- [Basic Operations](#basic-operations)
- [Traversal Operations](#traversal-operations)
- [Functional Operations](#functional-operations)
- [Collection Protocol Methods](#collection-protocol-methods)
- [Performance Considerations](#performance-considerations)

## Core Types

### TrieDictionary<Value>

The main trie dictionary type that stores string keys mapped to values of type `Value`.

```swift
public struct TrieDictionary<Value>
```

**Generic Parameters:**
- `Value`: The type of values stored in the dictionary

**Protocol Conformances:**
- `Collection`
- `Sequence` 
- `ExpressibleByDictionaryLiteral`
- `CustomStringConvertible`
- `CustomDebugStringConvertible`
- `Equatable` (when `Value: Equatable`)

## Initialization

### Default Initializer

Creates an empty TrieDictionary.

```swift
public init()
```

**Complexity:** O(1)

**Example:**
```swift
var trie = TrieDictionary<String>()
```

### Dictionary Literal Initializer

Creates a TrieDictionary from dictionary literal syntax.

```swift
public init(dictionaryLiteral elements: (String, Value)...)
```

**Parameters:**
- `elements`: Key-value pairs to populate the trie

**Complexity:** O(n×m) where n is the number of elements and m is the average key length

**Example:**
```swift
let trie: TrieDictionary<Int> = ["apple": 1, "banana": 2]
```

## Basic Operations

### Subscript Access

Accesses the value associated with the given key for reading and writing.

```swift
public subscript(key: String) -> Value?
```

**Parameters:**
- `key`: The string key to look up or modify

**Returns:** The value associated with the key, or `nil` if no value exists

**Complexity:** O(k) where k is the length of the key

**Example:**
```swift
trie["hello"] = "world"      // Set
let value = trie["hello"]    // Get: Optional("world")
trie["hello"] = nil          // Remove
```

### Update Value

Updates the value for a key and returns the previous value.

```swift
@discardableResult
public mutating func updateValue(_ value: Value, forKey key: String) -> Value?
```

**Parameters:**
- `value`: The value to associate with the key
- `key`: The key to update

**Returns:** The previous value associated with the key, or `nil` if the key was not present

**Complexity:** O(k) where k is the length of the key

### Remove Value

Removes the value for a key and returns the removed value.

```swift
@discardableResult
public mutating func removeValue(forKey key: String) -> Value?
```

**Parameters:**
- `key`: The key to remove

**Returns:** The value that was removed, or `nil` if the key was not present

**Complexity:** O(k) where k is the length of the key

### Remove All

Removes all key-value pairs from the trie.

```swift
public mutating func removeAll()
```

**Complexity:** O(1)

### Properties

#### isEmpty

Returns `true` if the trie contains no key-value pairs.

```swift
public var isEmpty: Bool
```

**Complexity:** O(1)

#### count

The number of key-value pairs stored in the trie.

```swift
public var count: Int
```

**Complexity:** O(n) where n is the number of nodes in the trie

**Note:** This traverses the entire trie structure to count values.

### Keys and Values

#### keys()

Returns an array containing all keys in the trie.

```swift
public func keys() -> [String]
```

**Returns:** An array of all keys in the trie

**Complexity:** O(n×m) where n is the number of keys and m is the average key length

#### values()

Returns an array containing all values in the trie.

```swift
public func values() -> [Value]
```

**Returns:** An array of all values in the trie

**Complexity:** O(n) where n is the number of key-value pairs

## Traversal Operations

### traverse(_:)

Returns a new TrieDictionary containing all key-value pairs whose keys start with the given prefix.

```swift
public func traverse(_ prefix: String) -> TrieDictionary<Value>
```

**Parameters:**
- `prefix`: The prefix to search for

**Returns:** A new TrieDictionary containing matching key-value pairs with prefix removed

**Complexity:** O(k) where k is the length of the prefix

**Example:**
```swift
let trie: TrieDictionary<String> = [
    "apple": "fruit",
    "application": "software", 
    "apply": "action"
]
let appTrie = trie.traverse("app")
// Contains: "le" -> "fruit", "lication" -> "software", "ly" -> "action"
```

### getValuesAlongPath(_:)

Returns an array of all values found along the path from root to the given key.

```swift
public func getValuesAlongPath(_ path: String) -> [Value]
```

**Parameters:**
- `path`: The path to traverse

**Returns:** An array of values encountered along the path

**Complexity:** O(k) where k is the length of the path

**Example:**
```swift
let trie: TrieDictionary<String> = ["a": "first", "app": "second", "apple": "third"]
let values = trie.getValuesAlongPath("apple")
// Result: ["first", "second", "third"]
```

### subtrie(at:)

Returns a new TrieDictionary containing only the subtrie at the given prefix.

```swift
public func subtrie(at prefix: String) -> TrieDictionary<Value>
```

**Parameters:**
- `prefix`: The prefix to use as the root of the subtrie

**Returns:** A new TrieDictionary containing the subtrie

**Complexity:** O(k) where k is the length of the prefix

**Note:** This is equivalent to `traverse(_:)`.

### subtries(at:)

Returns multiple subtries for the given prefixes.

```swift
public func subtries(at prefixes: [String]) -> TrieDictionary<TrieDictionary<Value>>
```

**Parameters:**
- `prefixes`: An array of prefixes to create subtries for

**Returns:** A TrieDictionary mapping prefixes to their subtries

**Complexity:** O(p×k) where p is the number of prefixes and k is the average prefix length

## Functional Operations

### Key Transformation

#### addingPrefix(_:)

Returns a new TrieDictionary where all keys are prefixed with the given string.

```swift
public func addingPrefix(_ prefix: String) -> TrieDictionary<Value>
```

**Parameters:**
- `prefix`: The string to prepend to all keys

**Returns:** A new TrieDictionary with prefixed keys

**Complexity:** O(n×m) where n is the number of keys and m is the average key length

#### addingSuffix(_:)

Returns a new TrieDictionary where all keys have the given suffix added.

```swift
public func addingSuffix(_ suffix: String) -> TrieDictionary<Value>
```

**Parameters:**
- `suffix`: The string to append to all keys

**Returns:** A new TrieDictionary with suffixed keys

**Complexity:** O(n×m) where n is the number of keys and m is the average key length

#### removingPrefix(_:)

Returns a new TrieDictionary where keys have the specified prefix removed.

```swift
public func removingPrefix(_ prefix: String) -> TrieDictionary<Value>
```

**Parameters:**
- `prefix`: The prefix to remove from keys

**Returns:** A new TrieDictionary with prefix removed from matching keys

**Complexity:** O(n×m) where n is the number of keys and m is the average key length

#### removingSuffix(_:)

Returns a new TrieDictionary where keys have the specified suffix removed.

```swift
public func removingSuffix(_ suffix: String) -> TrieDictionary<Value>
```

**Parameters:**
- `suffix`: The suffix to remove from keys

**Returns:** A new TrieDictionary with suffix removed from matching keys

**Complexity:** O(n×m) where n is the number of keys and m is the average key length

### Path Operations

#### gatheringValuesAlongPaths(_:)

Returns a TrieDictionary mapping paths to arrays of values found along each path.

```swift
public func gatheringValuesAlongPaths(_ paths: [String]) -> TrieDictionary<[Value]>
```

**Parameters:**
- `paths`: An array of paths to traverse

**Returns:** A TrieDictionary mapping each path to its collected values

**Complexity:** O(p×k) where p is the number of paths and k is the average path length

#### expandingToPathValues()

Returns a TrieDictionary where each existing key maps to all values found along its path.

```swift
public func expandingToPathValues() -> TrieDictionary<[Value]>
```

**Returns:** A TrieDictionary where values are arrays of path values

**Complexity:** O(n×k) where n is the number of keys and k is the average key length

### Value Transformation

#### mapValues(_:)

Returns a new TrieDictionary with the same keys but transformed values.

```swift
public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> TrieDictionary<T>
```

**Parameters:**
- `transform`: A closure that transforms each value

**Returns:** A new TrieDictionary with transformed values

**Complexity:** O(n) where n is the number of key-value pairs

#### compactMapValues(_:)

Returns a new TrieDictionary with transformed values, removing entries where transformation returns nil.

```swift
public func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> TrieDictionary<T>
```

**Parameters:**
- `transform`: A closure that transforms each value, returning nil to exclude entries

**Returns:** A new TrieDictionary with successfully transformed values

**Complexity:** O(n) where n is the number of key-value pairs

### Filtering

#### filter(_:)

Returns a new TrieDictionary containing only key-value pairs that satisfy the given predicate.

```swift
public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> TrieDictionary<Value>
```

**Parameters:**
- `isIncluded`: A closure that determines whether to include each key-value pair

**Returns:** A new TrieDictionary with filtered entries

**Complexity:** O(n) where n is the number of key-value pairs

#### filteringKeys(_:)

Returns a new TrieDictionary containing only keys that satisfy the given predicate.

```swift
public func filteringKeys(_ isIncluded: (String) throws -> Bool) rethrows -> TrieDictionary<Value>
```

**Parameters:**
- `isIncluded`: A closure that determines whether to include each key

**Returns:** A new TrieDictionary with filtered entries

**Complexity:** O(n) where n is the number of key-value pairs

#### filteringValues(_:)

Returns a new TrieDictionary containing only values that satisfy the given predicate.

```swift
public func filteringValues(_ isIncluded: (Value) throws -> Bool) rethrows -> TrieDictionary<Value>
```

**Parameters:**
- `isIncluded`: A closure that determines whether to include each value

**Returns:** A new TrieDictionary with filtered entries

**Complexity:** O(n) where n is the number of key-value pairs

### Merging

#### merge(_:uniquingKeysWith:)

Merges another TrieDictionary into this one, using a combining closure to resolve conflicts.

```swift
public mutating func merge(_ other: TrieDictionary<Value>, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows
```

**Parameters:**
- `other`: Another TrieDictionary to merge
- `combine`: A closure to resolve conflicts when keys exist in both tries

**Complexity:** O(m) where m is the number of key-value pairs in the other trie

#### merging(_:uniquingKeysWith:)

Returns a new TrieDictionary created by merging this one with another.

```swift
public func merging(_ other: TrieDictionary<Value>, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> TrieDictionary<Value>
```

**Parameters:**
- `other`: Another TrieDictionary to merge
- `combine`: A closure to resolve conflicts when keys exist in both tries

**Returns:** A new TrieDictionary containing merged entries

**Complexity:** O(n + m) where n and m are the number of key-value pairs in each trie

## Collection Protocol Methods

### Sequence Protocol

#### makeIterator()

Creates an iterator for traversing all key-value pairs.

```swift
public func makeIterator() -> TrieDictionaryIterator<Value>
```

**Returns:** A TrieDictionaryIterator for this trie

**Complexity:** O(n×m) where n is the number of keys and m is the average key length

### Collection Protocol

#### startIndex

The position of the first element in the collection.

```swift
public var startIndex: Index
```

**Returns:** Always 0 for non-empty collections

**Complexity:** O(1)

#### endIndex

The position one past the last element in the collection.

```swift
public var endIndex: Index
```

**Returns:** The count of key-value pairs

**Complexity:** O(n) where n is the number of nodes (due to count calculation)

#### index(after:)

Returns the index immediately after the given index.

```swift
public func index(after i: Index) -> Index
```

**Parameters:**
- `i`: The index to advance

**Returns:** The next index

**Complexity:** O(1)

#### subscript(position:)

Accesses the key-value pair at the specified position.

```swift
public subscript(position: Index) -> Element
```

**Parameters:**
- `position`: The position of the element to access

**Returns:** The key-value pair at the specified position

**Complexity:** O(n×m) where n is the number of keys and m is the average key length

**Warning:** This implementation has O(n×m) complexity due to key collection. For better performance, use direct key-based access or iteration methods.

## Performance Considerations

### Time Complexity Summary

| Operation | Complexity | Notes |
|-----------|------------|-------|
| `subscript[key]` | O(k) | k = key length |
| `updateValue(_:forKey:)` | O(k) | k = key length |
| `removeValue(forKey:)` | O(k) | k = key length |
| `keys()` | O(n×m) | n = # keys, m = avg key length |
| `values()` | O(n) | n = # key-value pairs |
| `count` | O(n) | n = # nodes |
| `isEmpty` | O(1) | - |
| `traverse(_:)` | O(k) | k = prefix length |
| `getValuesAlongPath(_:)` | O(k) | k = path length |
| `mapValues(_:)` | O(n) | n = # key-value pairs |
| `filter(_:)` | O(n) | n = # key-value pairs |
| `merge(_:uniquingKeysWith:)` | O(m) | m = # pairs in other trie |

### Memory Usage

- **Space Complexity:** O(n×p) where n = number of keys, p = average unique prefix length
- **Path Compression:** Significantly reduces memory for datasets with common prefixes
- **Overhead:** Each node stores compressed path, value (optional), and child array

### Best Practices

1. **Use `traverse()` for prefix operations** instead of `filter()` with `hasPrefix()`
2. **Pre-allocate when building large tries** by adding keys incrementally
3. **Leverage common prefixes** to maximize memory efficiency
4. **Use batch operations** when possible for better performance
5. **Avoid Collection subscript** for performance-critical code; use direct key access instead

### Thread Safety

TrieDictionary is **not thread-safe**. For concurrent access, implement external synchronization using dispatch queues or other synchronization primitives.