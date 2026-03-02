# ``TrieDictionary``

A high-performance compressed trie (prefix tree) with Dictionary-like API.

## Overview

TrieDictionary stores key-value pairs where keys are strings, using a compressed trie structure that minimizes memory by merging chains of single-child nodes. This makes it efficient for datasets with common prefixes.

```swift
var trie = TrieDictionary<String>()
trie["apple"] = "fruit"
trie["application"] = "software"
trie["apply"] = "action"

let appTrie = trie.traverse("app")
let values = trie.getValuesAlongPath("application")
```

### Performance

| Operation | Complexity |
|-----------|-----------|
| Insertion | O(k) |
| Lookup | O(k) |
| Deletion | O(k) |

Where *k* is the length of the key.

## Topics

### Creating a Trie

- ``TrieDictionary/init()``

### Accessing Values

- ``TrieDictionary/subscript(_:)``
- ``TrieDictionary/keys()``
- ``TrieDictionary/values()``
- ``TrieDictionary/isEmpty``
- ``TrieDictionary/count``

### Modifying the Trie

- ``TrieDictionary/updateValue(_:forKey:)``
- ``TrieDictionary/removeValue(forKey:)``
- ``TrieDictionary/removeAll()``

### Prefix Operations

- ``TrieDictionary/traverse(_:)``
- ``TrieDictionary/subtrie(at:)``
- ``TrieDictionary/addingPrefix(_:)``
- ``TrieDictionary/getValuesAlongPath(_:)``
- ``TrieDictionary/gatheringValuesAlongPaths(_:)``

### Merging

- ``TrieDictionary/merging(other:uniquingKeysWith:)``

### Transformations

- ``TrieDictionary/mapValues(_:)``
- ``TrieDictionary/compactMapValues(_:)``
