import XCTest
@testable import TrieDictionary

final class PerformanceTests: XCTestCase {

    // MARK: - Core Operations

    func testInsertionPerformance() {
        let words = generateWords(count: 10_000)
        measure {
            var trie = TrieDictionary<Int>()
            for (i, word) in words.enumerated() {
                trie[word] = i
            }
        }
    }

    func testLookupPerformance() {
        let words = generateWords(count: 10_000)
        var trie = TrieDictionary<Int>()
        for (i, word) in words.enumerated() { trie[word] = i }

        measure {
            for word in words {
                _ = trie[word]
            }
        }
    }

    func testRemovalPerformance() {
        let keys = (0..<1000).map { "key\($0)" }
        var trie = TrieDictionary<Int>()
        for (i, key) in keys.enumerated() { trie[key] = i }

        measure {
            for key in keys {
                trie.removeValue(forKey: key)
            }
        }
    }

    // MARK: - Traversal

    func testTraversalPerformance() {
        let words = generateWords(count: 5_000)
        var trie = TrieDictionary<Int>()
        for (i, word) in words.enumerated() { trie[word] = i }
        let prefixes = Array(words.prefix(100)).map { String($0.prefix(3)) }

        measure {
            for prefix in prefixes {
                _ = trie.traverse(prefix)
            }
        }
    }

    func testPathValuesPerformance() {
        let words = generateWords(count: 5_000)
        var trie = TrieDictionary<Int>()
        for (i, word) in words.enumerated() { trie[word] = i }
        let paths = Array(words.prefix(1_000))

        measure {
            for path in paths {
                _ = trie.getValuesAlongPath(path)
            }
        }
    }

    // MARK: - Iteration

    func testIterationPerformance() {
        var trie = TrieDictionary<Int>()
        for i in 0..<5_000 { trie["key\(i)"] = i }

        measure {
            var sum = 0
            for (_, value) in trie { sum += value }
        }
    }

    // MARK: - Transformations

    func testAddingPrefixPerformance() {
        let words = generateWords(count: 2_000)
        var trie = TrieDictionary<Int>()
        for (i, word) in words.enumerated() { trie[word] = i }

        measure {
            _ = trie.addingPrefix("test_")
        }
    }

    // MARK: - Common Prefix Efficiency

    func testCommonPrefixInsertLookup() {
        measure {
            var trie = TrieDictionary<String>()
            let prefix = "com.example.app.module.component."
            for i in 0..<1_000 {
                trie["\(prefix)item\(i)"] = "value\(i)"
            }
            for i in 0..<1_000 {
                _ = trie["\(prefix)item\(i)"]
            }
        }
    }

    // MARK: - Helpers

    private func generateWords(count: Int) -> [String] {
        let chars = "abcdefghijklmnopqrstuvwxyz"
        return (0..<count).map { i in
            let length = (i % 15) + 3
            var word = String((0..<length).map { _ in chars.randomElement()! })
            if i % 10 == 0 { word = "common_" + word }
            else if i % 15 == 0 { word = "test_" + word }
            return word
        }
    }
}
