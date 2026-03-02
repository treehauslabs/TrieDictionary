# TrieDictionary

A compressed trie (radix tree) that works like Swift's `Dictionary<String, Value>` but is purpose-built for string keys with shared prefixes.

[![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20Linux-lightgrey.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Why TrieDictionary?

Swift's `Dictionary` hashes entire keys. When thousands of keys share long prefixes (URLs, config paths, namespaced identifiers), that work is redundant and memory is wasted storing duplicate prefix bytes.

TrieDictionary stores shared prefixes once via **path compression** (radix tree), then provides operations that exploit the prefix structure:

| What you get | How |
|---|---|
| **O(k) lookup/insert/delete** | Walk the key character-by-character, same as Dictionary |
| **O(k) prefix queries** | `traverse("app")` returns a subtrie of all `app*` keys — no scan |
| **O(k) path value collection** | `getValuesAlongPath("/a/b/c")` collects every value from root to leaf |
| **Up to 80% less memory** | Shared prefixes stored once, not per-key |
| **Zero-allocation reads** | Lookups compare characters in-place via String.Index walking |

*Where k = key length. Dictionary is O(1) amortized via hashing, but trie operations are key-length bounded regardless of collection size.*

**Use TrieDictionary when** your keys have structure — dot-separated config paths, URL routes, filesystem paths, namespaced identifiers. **Use Dictionary when** your keys are random/unrelated strings (no prefix sharing to exploit).

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/TrieDictionary.git", from: "1.0.0")
]
```

## Usage

Every example below is an [executable test](Tests/TrieDictionaryTests/UsageExampleTests.swift) — they compile and pass.

### Autocomplete / Search Suggestions

`traverse()` returns a subtrie of all keys matching a prefix in O(k) time. No scanning.

```swift
var words = TrieDictionary<Int>()
words["swift"] = 1
words["swimming"] = 2
words["swing"] = 3
words["switch"] = 4
words["symbol"] = 5
words["system"] = 6

// User types "sw" → find all completions
let completions = words.traverse("sw")
completions.keys() // ["ift", "imming", "ing", "itch"]

// Narrow further to "swi"
let narrowed = words.traverse("swi")
narrowed.keys() // ["ft", "mming", "ng", "tch"]
```

### Configuration Management

Dot-separated keys map naturally to a trie. Pull out entire sections with `traverse()`.

```swift
let config: TrieDictionary<String> = [
    "database.host": "localhost",
    "database.port": "5432",
    "database.name": "myapp",
    "database.pool.min": "2",
    "database.pool.max": "10",
    "server.host": "0.0.0.0",
    "server.port": "8080",
    "logging.level": "info",
    "logging.format": "json"
]

// Pull all database config as its own TrieDictionary
let dbConfig = config.traverse("database.")
dbConfig["host"]     // "localhost"
dbConfig["port"]     // "5432"
dbConfig["pool.min"] // "2"
dbConfig["pool.max"] // "10"

// Pull just the pool settings
let poolConfig = config.traverse("database.pool.")
poolConfig["min"] // "2"
poolConfig["max"] // "10"
```

### URL Routing

Map URL paths to handler names. Resolve individual routes or query entire path segments.

```swift
let routes: TrieDictionary<String> = [
    "/api/v1/users": "listUsers",
    "/api/v1/users/create": "createUser",
    "/api/v1/users/delete": "deleteUser",
    "/api/v1/posts": "listPosts",
    "/api/v1/posts/create": "createPost",
    "/api/v2/users": "listUsersV2",
    "/health": "healthCheck"
]

// Resolve a specific route
routes["/api/v1/users"]  // "listUsers"
routes["/health"]        // "healthCheck"

// Get all v1 user routes
let userRoutes = routes.traverse("/api/v1/users")
userRoutes[""]        // "listUsers"
userRoutes["/create"] // "createUser"
userRoutes["/delete"] // "deleteUser"

// Get all v1 vs v2 routes
routes.traverse("/api/v1/").count // 5
routes.traverse("/api/v2/").count // 1
```

### Hierarchical Permissions (RBAC)

`getValuesAlongPath()` collects every value from root to a target path — natural permission inheritance.

```swift
var permissions = TrieDictionary<String>()
permissions["/"] = "authenticated"
permissions["/admin"] = "admin_role"
permissions["/admin/users"] = "user_manager"
permissions["/admin/users/delete"] = "super_admin"

// To access /admin/users/delete, all these permissions are required:
permissions.getValuesAlongPath("/admin/users/delete")
// ["authenticated", "admin_role", "user_manager", "super_admin"]

// /admin only needs the first two
permissions.getValuesAlongPath("/admin")
// ["authenticated", "admin_role"]
```

### Feature Flags with Namespaces

Organize flags by team. Use `traverse()` to pull a team's flags, `filter()` to find enabled ones.

```swift
var flags = TrieDictionary<Bool>()
flags["payments.stripe_v2"] = true
flags["payments.refund_flow"] = false
flags["payments.crypto"] = false
flags["search.semantic"] = true
flags["search.autocomplete_v3"] = true
flags["auth.oauth2"] = true
flags["auth.passkeys"] = false

// Get all flags for the payments team
let paymentFlags = flags.traverse("payments.")
paymentFlags["stripe_v2"]  // true
paymentFlags["refund_flow"] // false

// Count enabled flags for the search team
flags.traverse("search.").filter { $0.value == true }.count // 2

// Keep original keys with withPrefix()
let authFlags = flags.withPrefix("auth.")
authFlags["auth.oauth2"]   // true
authFlags["auth.passkeys"] // false
```

### Dictionary-Like Operations

TrieDictionary conforms to `Collection`, `Sequence`, `ExpressibleByDictionaryLiteral`, and `Equatable` (when `Value: Equatable`). All the familiar operations work.

```swift
// Dictionary literal initialization
var inventory: TrieDictionary<Int> = [
    "apple": 50,
    "apricot": 30,
    "banana": 25,
    "blueberry": 100
]

// Subscript get/set
inventory["apple"]   // 50
inventory["cherry"] = 15

// Update with old value returned
let old = inventory.updateValue(60, forKey: "apple") // returns 50

// Remove with old value returned
let removed = inventory.removeValue(forKey: "banana") // returns 25

// Iterate
for (fruit, count) in inventory {
    print("\(fruit): \(count)")
}

// map, filter, reduce via Collection conformance
let doubled = inventory.mapValues { $0 * 2 }
let plenty = inventory.filter { $0.value >= 50 }
let total = inventory.reduce(0) { $0 + $1.value }
```

### Immutable Transformations

TrieDictionary is a value type. Immutable APIs return new instances — ideal for functional pipelines.

```swift
let scores: TrieDictionary<Int> = [
    "alice": 85, "bob": 92, "charlie": 78,
    "diana": 95, "eve": 88
]

// Build a leaderboard: keep scores >= 85, format, namespace
let leaderboard = scores
    .filter { $0.value >= 85 }
    .mapValues { "\($0) pts" }
    .addingPrefix("scores.")

leaderboard["scores.alice"] // "85 pts"
leaderboard["scores.bob"]   // "92 pts"
leaderboard["scores.diana"] // "95 pts"
leaderboard["scores.eve"]   // "88 pts"
// charlie filtered out (78 < 85)

// Original is unchanged
scores.count      // 5
scores["charlie"] // 78
```

### Merging Data Sources

Combine two TrieDictionaries with a conflict-resolution strategy.

```swift
let local: TrieDictionary<Int> = [
    "settings.theme": 1,
    "settings.fontSize": 14,
    "cache.ttl": 300
]
let remote: TrieDictionary<Int> = [
    "settings.theme": 2,
    "settings.language": 1,
    "cache.ttl": 600
]

// Remote wins on conflict
let merged = local.merging(remote) { _, remote in remote }
merged["settings.theme"]    // 2   (remote wins)
merged["settings.fontSize"] // 14  (local only)
merged["settings.language"] // 1   (remote only)
merged["cache.ttl"]         // 600 (remote wins)
```

## Performance

| Operation | Time Complexity | Space Complexity |
|-----------|----------------|------------------|
| Insertion | O(k) | O(k) |
| Lookup | O(k) | O(1) |
| Deletion | O(k) | O(1) |
| Prefix query (`traverse`) | O(k) | O(1) |
| Path values (`getValuesAlongPath`) | O(k) | O(v) |
| Iteration | O(n*m) | O(n) |

*k = key length, n = number of keys, m = average key length, v = values along path*

**Memory**: O(n * p) where p = average unique prefix length. For keys sharing long prefixes, this is significantly less than n * k.

### Implementation Details

- **Path compression**: Single-child chains are collapsed into compressed path strings (radix tree)
- **Bitmap-indexed child storage**: 32-bit bitmap with popcount indexing, similar to [Swift Collections' TreeDictionary](https://github.com/apple/swift-collections)
- **Zero-allocation lookups**: Key comparison walks String indices in-place — no ArraySlice heap allocation
- **Structural transformations**: `mapValues` and `compactMapValues` traverse the trie structure directly instead of re-inserting via keys
- **Single-pass iteration**: Iterator collects all (key, value) pairs in one tree walk

## API Reference

### Core Operations

| Method | Description |
|--------|-------------|
| `subscript[key]` | Get/set value for key |
| `updateValue(_:forKey:)` | Set value, return old |
| `removeValue(forKey:)` | Remove value, return old |
| `removeAll()` | Clear all entries |
| `keys()` / `values()` | Get all keys/values |
| `count` / `isEmpty` | Size queries |

### Traversal

| Method | Description |
|--------|-------------|
| `traverse(_:)` | Subtrie at prefix (prefix stripped from keys) |
| `withPrefix(_:)` | Entries matching prefix (original keys preserved) |
| `getValuesAlongPath(_:)` | All values from root to path |
| `subtrie(at:)` | Alias for `traverse` |
| `traverseChild(_:)` | Single-character child lookup |
| `traverseToNextChild(_:)` | Child with compressed path info |

### Transformations

| Method | Description |
|--------|-------------|
| `mapValues(_:)` | Transform values (structural) |
| `compactMapValues(_:)` | Transform values, drop nils (structural) |
| `mapKeys(_:)` | Transform keys |
| `filter(_:)` | Filter key-value pairs |
| `addingPrefix(_:)` | Prepend prefix to all keys |
| `withSuffix(_:)` | Keep entries with suffix |
| `partitioned(by:)` | Split into (matching, nonMatching) |
| `merge(other:mergeRule:)` | Structural merge of two tries |
| `merging(_:uniquingKeysWith:)` | Merge (Dictionary-style API) |

### Immutable Operations

| Method | Description |
|--------|-------------|
| `setting(key:value:)` | Return new trie with key set |
| `setting(_:)` | Variadic/sequence batch set |
| `removing(key:)` / `removing(_:)` | Return new trie with key(s) removed |
| `removingAll()` / `removingAll(where:)` | Return new empty/filtered trie |
| `keepingOnly(where:)` | Return new trie keeping matches |

## Testing

```bash
swift test                          # All tests
swift test --filter PerformanceTests # Benchmarks only
swift test --filter UsageExampleTests # Usage examples only
```

Test suite structure:
- **CoreOperationsTests** — insert, lookup, update, remove, keys, values
- **TraversalTests** — traverse, subtrie, traverseChild, getValuesAlongPath
- **TransformationTests** — mapValues, filter, mapKeys, prefix/suffix ops
- **ImmutableOperationsTests** — functional setting/removing/chaining
- **MergeTests** — structural merge, mutating merge, merging
- **CompressionTests** — path compression invariants, randomized stress tests
- **ProtocolConformanceTests** — Collection, Sequence, Equatable, literals
- **PerformanceTests** — benchmarks for core operations
- **UsageExampleTests** — real-world examples (also in this README)

## Requirements

- Swift 6.0+
- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Linux (Swift 6.0+)

## License

MIT License — see [LICENSE](LICENSE) for details.
