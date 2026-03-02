import XCTest
@testable import TrieDictionary

final class CompressionTests: XCTestCase {

    // MARK: - Basic Compression Invariants

    func testEmptyTrieIsCompressed() {
        XCTAssertTrue(TrieDictionary<String>().isFullyCompressed)
    }

    func testSingleKeyIsCompressed() {
        let dict: TrieDictionary<String> = ["hello": "world"]
        XCTAssertTrue(dict.isFullyCompressed)
        XCTAssertEqual(dict["hello"], "world")
    }

    func testCompressionAfterInsertion() {
        var dict = TrieDictionary<String>()
        dict["a"] = "value_a"
        dict["abc"] = "value_abc"
        XCTAssertTrue(dict.isFullyCompressed)
        XCTAssertEqual(dict["a"], "value_a")
        XCTAssertEqual(dict["abc"], "value_abc")
        XCTAssertNil(dict["ab"])
    }

    func testCompressionWithLongChains() {
        var dict = TrieDictionary<String>()
        dict["a"] = "value_a"
        dict["abcdefghijk"] = "value_long"
        XCTAssertTrue(dict.isFullyCompressed)
        XCTAssertEqual(dict["a"], "value_a")
        XCTAssertEqual(dict["abcdefghijk"], "value_long")
    }

    func testCompressionAfterRemoval() {
        var dict = TrieDictionary<String>()
        dict["a"] = "value_a"
        dict["ab"] = "value_ab"
        dict["abc"] = "value_abc"
        dict["ab"] = nil

        XCTAssertEqual(dict["a"], "value_a")
        XCTAssertEqual(dict["abc"], "value_abc")
        XCTAssertNil(dict["ab"])
    }

    func testCompressionAfterMultipleOperations() {
        var dict = TrieDictionary<String>()
        dict["test"] = "value1"
        dict["testing"] = "value2"
        dict["tested"] = "value3"
        XCTAssertTrue(dict.isFullyCompressed)

        dict["testing"] = nil
        XCTAssertEqual(dict["test"], "value1")
        XCTAssertEqual(dict["tested"], "value3")
        XCTAssertNil(dict["testing"])
    }

    func testCompressionComplexStructure() {
        let dict: TrieDictionary<String> = [
            "app": "application", "apple": "fruit", "apply": "action",
            "appreciate": "value", "approach": "method"
        ]
        XCTAssertEqual(dict["app"], "application")
        XCTAssertEqual(dict["apple"], "fruit")
        XCTAssertEqual(dict["apply"], "action")
        XCTAssertEqual(dict["appreciate"], "value")
        XCTAssertEqual(dict["approach"], "method")
    }

    func testCompressionAfterClearAndRebuild() {
        var dict = TrieDictionary<String>()
        dict["test"] = "v1"
        dict["testing"] = "v2"
        dict["temp"] = "v3"
        dict.removeAll()
        XCTAssertTrue(dict.isFullyCompressed)

        dict["new"] = "v1"
        dict["newer"] = "v2"
        dict["newest"] = "v3"
        XCTAssertEqual(dict["new"], "v1")
        XCTAssertEqual(dict["newer"], "v2")
        XCTAssertEqual(dict["newest"], "v3")
    }

    func testIntermediateRemovalPreservesAccessibility() {
        var dict = TrieDictionary<String>()
        dict["m"] = "value_m"
        dict["ma"] = "value_ma"
        dict["mab"] = "value_mab"

        dict["ma"] = nil
        XCTAssertEqual(dict["m"], "value_m")
        XCTAssertEqual(dict["mab"], "value_mab")
        XCTAssertNil(dict["ma"])
    }

    func testMergePreservesCompression() {
        let a: TrieDictionary<Int> = ["verylongkey": 1]
        let b: TrieDictionary<Int> = ["verylongkeyword": 2]
        let merged = a.merge(other: b) { a, b in a + b }
        XCTAssertEqual(merged["verylongkey"], 1)
        XCTAssertEqual(merged["verylongkeyword"], 2)
        XCTAssertTrue(merged.isFullyCompressed)
    }

    // MARK: - Randomized Stress Tests

    func testRandomizedInsertAndRemove() {
        var dict = TrieDictionary<String>()
        var currentKeys: Set<String> = []

        for i in 0..<200 {
            let shouldInsert = currentKeys.isEmpty || Bool.random()
            if shouldInsert {
                let key = randomString(maxLength: 8)
                dict[key] = "value_\(i)"
                currentKeys.insert(key)
            } else if let keyToRemove = currentKeys.randomElement() {
                dict[keyToRemove] = nil
                currentKeys.remove(keyToRemove)
            }
        }

        for key in dict.keys() {
            XCTAssertNotNil(dict[key])
        }
    }

    func testRandomizedPrefixChains() {
        var dict = TrieDictionary<String>()
        let groups = [
            ["test", "testing", "tester", "tests", "testimony"],
            ["app", "apple", "application", "apply", "appreciate"],
            ["data", "database", "datum", "date", "dateline"],
            ["a", "ab", "abc", "abcd", "abcde"]
        ]
        var allKeys: [String] = []
        for group in groups { allKeys.append(contentsOf: group) }

        for (i, key) in allKeys.enumerated() {
            dict[key] = "value_\(i)"
        }

        let keysToRemove = Array(allKeys.shuffled().prefix(allKeys.count / 2))
        for key in keysToRemove {
            dict[key] = nil
        }

        for key in dict.keys() {
            XCTAssertNotNil(dict[key])
        }
    }

    func testRandomizedEdgeCases() {
        var dict = TrieDictionary<String>()
        let edgeCases = [
            "", "a", "aa", "aaa", "aaaa",
            "ab", "ba",
            "abcdefghijklmnopqrstuvwxyz",
            "\u{1F680}", "\u{1F680}\u{1F31F}"
        ]

        for (i, key) in edgeCases.enumerated() {
            dict[key] = "edge_\(i)"
        }

        let random = (0..<15).map { _ in randomString(maxLength: 5) }
        for (i, key) in random.enumerated() {
            dict[key] = "random_\(i)"
        }

        let keysToRemove = Array(dict.keys().shuffled().prefix(dict.count / 2))
        for key in keysToRemove {
            dict[key] = nil
        }

        for key in dict.keys() {
            XCTAssertNotNil(dict[key])
        }
    }

    // MARK: - Helpers

    private func randomString(maxLength: Int) -> String {
        let chars = "abcdefghijklmnopqrstuvwxyz0123456789"
        let length = Int.random(in: 1...maxLength)
        return String((0..<length).map { _ in chars.randomElement()! })
    }
}
