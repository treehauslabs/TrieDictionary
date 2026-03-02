import Foundation

/**
 Extensions providing additional functionality to TrieDictionary.
 
 This file contains protocol conformances and additional methods that enhance
 the TrieDictionary with standard Swift collection behaviors and functional programming patterns.
 */

// MARK: - Dictionary Literal Support

/**
 Enables TrieDictionary to be initialized with dictionary literal syntax.
 
 This allows you to write:
 ```swift
 let trie: TrieDictionary<String> = ["apple": "fruit", "tree": "plant"]
 ```
 */
extension TrieDictionary: ExpressibleByDictionaryLiteral {
    /**
     Creates a TrieDictionary from dictionary literal elements.
     
     - Parameter elements: Key-value pairs to populate the trie
     - Complexity: O(n*m) where n is the number of elements and m is the average key length
     */
    public init(dictionaryLiteral elements: (String, Value)...) {
        self.init()
        for (key, value) in elements {
            self[key] = value
        }
    }
}

// MARK: - String Representation

/**
 Provides a human-readable description of the TrieDictionary.
 */
extension TrieDictionary: CustomStringConvertible {
    /**
     A textual representation of the TrieDictionary in dictionary format.
     
     - Returns: A string representation like `["key1": value1, "key2": value2]`
     */
    public var description: String {
        let keyValuePairs = self.map { "\"\($0.key)\": \($0.value)" }
        return "[\(keyValuePairs.joined(separator: ", "))]"
    }
}

/**
 Provides a debug-friendly description of the TrieDictionary.
 */
extension TrieDictionary: CustomDebugStringConvertible {
    /**
     A detailed textual representation suitable for debugging.
     
     - Returns: A string like `TrieDictionary(["key1": value1, "key2": value2])`
     */
    public var debugDescription: String {
        return "TrieDictionary(\(description))"
    }
}

// MARK: - Equality

/**
 Provides equality comparison for TrieDictionary when values are Equatable.
 */
extension TrieDictionary: Equatable where Value: Equatable {
    /**
     Returns `true` if both tries contain the same key-value pairs.
     
     Two TrieDictionaries are considered equal if they contain the same keys
     mapped to equal values, regardless of the internal trie structure.
     
     - Parameter lhs: The first TrieDictionary to compare
     - Parameter rhs: The second TrieDictionary to compare
     - Returns: `true` if the tries are equal, `false` otherwise
     - Complexity: O(n) where n is the number of key-value pairs
     */
    public static func == (lhs: TrieDictionary<Value>, rhs: TrieDictionary<Value>) -> Bool {
        guard lhs.count == rhs.count else { return false }
        
        for (key, value) in lhs {
            guard let rhsValue = rhs[key], rhsValue == value else {
                return false
            }
        }
        return true
    }
}

// MARK: - Functional Programming

/**
 Functional programming methods for transforming and manipulating TrieDictionary contents.
 */
extension TrieDictionary {
    /**
     Returns a new TrieDictionary containing only key-value pairs that satisfy the given predicate.
     
     ```swift
     let scores: TrieDictionary<Int> = ["alice": 85, "bob": 92, "charlie": 78]
     let highScores = scores.filter { $0.value >= 80 }
     // Result: ["alice": 85, "bob": 92]
     ```
     
     - Parameter isIncluded: A closure that determines whether to include each key-value pair
     - Returns: A new TrieDictionary with filtered entries
     - Complexity: O(n) where n is the number of key-value pairs
     */
    public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> TrieDictionary<Value> {
        var result = TrieDictionary<Value>()
        for element in self {
            if try isIncluded(element) {
                result[element.key] = element.value
            }
        }
        return result
    }
    
    /**
     Merges another TrieDictionary into this one, using a combining closure to resolve conflicts.
     
     ```swift
     var scores: TrieDictionary<Int> = ["alice": 85, "bob": 92]
     let bonuses: TrieDictionary<Int> = ["alice": 10, "charlie": 5]
     scores.merge(bonuses, uniquingKeysWith: +)
     // Result: ["alice": 95, "bob": 92, "charlie": 5]
     ```
     
     - Parameter other: Another TrieDictionary to merge
     - Parameter combine: A closure to resolve conflicts when keys exist in both tries
     - Complexity: O(m) where m is the number of key-value pairs in the other trie
     */
    public mutating func merge(_ other: TrieDictionary<Value>, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows {
        for (key, value) in other {
            if let existingValue = self[key] {
                self[key] = try combine(existingValue, value)
            } else {
                self[key] = value
            }
        }
    }
    
    /**
     Returns a new TrieDictionary created by merging this one with another.
     
     - Parameter other: Another TrieDictionary to merge
     - Parameter combine: A closure to resolve conflicts when keys exist in both tries
     - Returns: A new TrieDictionary containing merged entries
     - Complexity: O(n + m) where n and m are the number of key-value pairs in each trie
     */
    public func merging(_ other: TrieDictionary<Value>, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> TrieDictionary<Value> {
        var result = self
        try result.merge(other, uniquingKeysWith: combine)
        return result
    }
    
}

// MARK: - Immutable Operations

/**
 Immutable operations that return new TrieDictionary instances without modifying the original.
 */
extension TrieDictionary {
    
    /**
     Returns a new TrieDictionary with the given key-value pair added or updated.
     
     - Parameter key: The key to set
     - Parameter value: The value to associate with the key
     - Returns: A new TrieDictionary with the update applied
     - Complexity: O(k) where k is the length of the key
     */
    public func setting(key: String, value: Value) -> TrieDictionary<Value> {
        var result = self
        result[key] = value
        return result
    }
    
    public func setting(_ pairs: (String, Value)...) -> TrieDictionary<Value> {
        var result = self
        for (key, value) in pairs {
            result[key] = value
        }
        return result
    }
    
    public func setting<S: Sequence>(_ pairs: S) -> TrieDictionary<Value> where S.Element == (String, Value) {
        var result = self
        for (key, value) in pairs {
            result[key] = value
        }
        return result
    }
    
    public func updatingValue(_ value: Value, forKey key: String) -> (TrieDictionary<Value>, Value?) {
        var result = self
        let oldValue = result.updateValue(value, forKey: key)
        return (result, oldValue)
    }
    
    public func removingValue(forKey key: String) -> (TrieDictionary<Value>, Value?) {
        var result = self
        let oldValue = result.removeValue(forKey: key)
        return (result, oldValue)
    }
    
    public func removing(key: String) -> TrieDictionary<Value> {
        var result = self
        result[key] = nil
        return result
    }
    
    public func removing(_ keys: String...) -> TrieDictionary<Value> {
        var result = self
        for key in keys {
            result[key] = nil
        }
        return result
    }
    
    public func removing<S: Sequence>(_ keys: S) -> TrieDictionary<Value> where S.Element == String {
        var result = self
        for key in keys {
            result[key] = nil
        }
        return result
    }
    
    public func removingAll() -> TrieDictionary<Value> {
        return TrieDictionary<Value>()
    }
    
    public func removingAll(where shouldRemove: (Element) throws -> Bool) rethrows -> TrieDictionary<Value> {
        var result = TrieDictionary<Value>()
        for element in self {
            if try !shouldRemove(element) {
                result[element.key] = element.value
            }
        }
        return result
    }
    
    public func keepingOnly(where shouldKeep: (Element) throws -> Bool) rethrows -> TrieDictionary<Value> {
        var result = TrieDictionary<Value>()
        for element in self {
            if try shouldKeep(element) {
                result[element.key] = element.value
            }
        }
        return result
    }
    
}

// MARK: - Advanced Filtering and Transformation

/**
 Advanced methods for filtering and transforming TrieDictionary contents.
 */
extension TrieDictionary {
    /**
     Returns a new TrieDictionary containing only keys that satisfy the given predicate.
     
     ```swift
     let data: TrieDictionary<String> = ["apple": "fruit", "car": "vehicle", "application": "software"]
     let longKeys = data.filteringKeys { $0.count > 5 }
     // Result: ["application": "software"]
     ```
     
     - Parameter isIncluded: A closure that determines whether to include each key
     - Returns: A new TrieDictionary with filtered entries
     - Complexity: O(n) where n is the number of key-value pairs
     */
    public func filteringKeys(_ isIncluded: (String) throws -> Bool) rethrows -> TrieDictionary<Value> {
        var result = TrieDictionary<Value>()
        for (key, value) in self {
            if try isIncluded(key) {
                result[key] = value
            }
        }
        return result
    }
    
    /**
     Returns a new TrieDictionary containing only values that satisfy the given predicate.
     
     - Parameter isIncluded: A closure that determines whether to include each value
     - Returns: A new TrieDictionary with filtered entries
     - Complexity: O(n) where n is the number of key-value pairs
     */
    public func filteringValues(_ isIncluded: (Value) throws -> Bool) rethrows -> TrieDictionary<Value> {
        var result = TrieDictionary<Value>()
        for (key, value) in self {
            if try isIncluded(value) {
                result[key] = value
            }
        }
        return result
    }
    
    /**
     Returns a new TrieDictionary with keys transformed by the given closure.
     
     ```swift
     let data: TrieDictionary<String> = ["apple": "fruit", "tree": "plant"]
     let uppercased = data.mapKeys { $0.uppercased() }
     // Result: ["APPLE": "fruit", "TREE": "plant"]
     ```
     
     - Parameter transform: A closure that transforms each key
     - Returns: A new TrieDictionary with transformed keys
     - Complexity: O(n*m) where n is the number of key-value pairs and m is the average key length
     */
    public func mapKeys(_ transform: (String) throws -> String) rethrows -> TrieDictionary<Value> {
        var result = TrieDictionary<Value>()
        for (key, value) in self {
            let newKey = try transform(key)
            result[newKey] = value
        }
        return result
    }
    
    /// Returns a new TrieDictionary containing only keys with the specified prefix
    public func withPrefix(_ prefix: String) -> TrieDictionary<Value> {
        if prefix.isEmpty { return self }
        let subtrie = traverse(prefix)
        if subtrie.isEmpty { return TrieDictionary<Value>() }
        return subtrie.addingPrefix(prefix)
    }
    
    /// Returns a new TrieDictionary containing only keys with the specified suffix
    public func withSuffix(_ suffix: String) -> TrieDictionary<Value> {
        return filteringKeys { $0.hasSuffix(suffix) }
    }
    
    /// Returns a new TrieDictionary containing only keys matching the specified pattern
    public func matching(_ predicate: (String) -> Bool) -> TrieDictionary<Value> {
        return filteringKeys(predicate)
    }
    
    /// Returns a tuple of two TrieDictionaries: (matching, nonMatching) based on the predicate
    public func partitioned(by predicate: (Element) throws -> Bool) rethrows -> (matching: TrieDictionary<Value>, nonMatching: TrieDictionary<Value>) {
        var matching = TrieDictionary<Value>()
        var nonMatching = TrieDictionary<Value>()
        
        for element in self {
            if try predicate(element) {
                matching[element.key] = element.value
            } else {
                nonMatching[element.key] = element.value
            }
        }
        
        return (matching, nonMatching)
    }
    
    /// Returns a new TrieDictionary with all values replaced by the result of the given closure applied to the key-value pair
    public func replacingValues<T>(_ transform: (String, Value) throws -> T) rethrows -> TrieDictionary<T> {
        var result = TrieDictionary<T>()
        for (key, value) in self {
            result[key] = try transform(key, value)
        }
        return result
    }
    
    /// Returns a new TrieDictionary containing only entries where the key length matches the condition
    public func filteringKeyLength(_ condition: (Int) -> Bool) -> TrieDictionary<Value> {
        return filteringKeys { condition($0.count) }
    }
    
    /// Returns a new TrieDictionary with keys having a minimum length
    public func withMinKeyLength(_ minLength: Int) -> TrieDictionary<Value> {
        return filteringKeyLength { $0 >= minLength }
    }
    
    /// Returns a new TrieDictionary with keys having a maximum length
    public func withMaxKeyLength(_ maxLength: Int) -> TrieDictionary<Value> {
        return filteringKeyLength { $0 <= maxLength }
    }
    
    /// Returns a new TrieDictionary with keys having an exact length
    public func withKeyLength(_ exactLength: Int) -> TrieDictionary<Value> {
        return filteringKeyLength { $0 == exactLength }
    }
    
    /// Returns a new TrieDictionary containing entries where values are unique
    public func uniqueValues() -> TrieDictionary<Value> where Value: Hashable {
        var seenValues = Set<Value>()
        var result = TrieDictionary<Value>()
        
        for (key, value) in self {
            if !seenValues.contains(value) {
                seenValues.insert(value)
                result[key] = value
            }
        }
        
        return result
    }
    
    /// Returns a new TrieDictionary by applying a transformation and then filtering out nils
    public func transformAndFilter<T>(_ transform: (Element) throws -> (String, T)?) rethrows -> TrieDictionary<T> {
        var result = TrieDictionary<T>()
        for element in self {
            if let (newKey, newValue) = try transform(element) {
                result[newKey] = newValue
            }
        }
        return result
    }
}