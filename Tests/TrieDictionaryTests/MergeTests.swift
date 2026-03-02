import XCTest
@testable import TrieDictionary

final class MergeTests: XCTestCase {

    // MARK: - Structural merge(other:mergeRule:)

    func testMergeEmptyTries() {
        let a = TrieDictionary<Int>()
        let b = TrieDictionary<Int>()
        let merged = a.merge(other: b) { a, b in a + b }
        XCTAssertTrue(merged.isEmpty)
    }

    func testMergeWithEmpty() {
        let a: TrieDictionary<String> = ["apple": "red", "banana": "yellow"]
        let merged = a.merge(other: TrieDictionary()) { a, _ in a }
        XCTAssertEqual(merged.count, 2)
        XCTAssertEqual(merged["apple"], "red")
    }

    func testMergeEmptyWithNonEmpty() {
        let b: TrieDictionary<String> = ["cherry": "red"]
        let merged = TrieDictionary<String>().merge(other: b) { a, _ in a }
        XCTAssertEqual(merged["cherry"], "red")
    }

    func testMergeDisjointKeys() {
        let a: TrieDictionary<Int> = ["apple": 1, "banana": 2]
        let b: TrieDictionary<Int> = ["cherry": 3, "date": 4]
        let merged = a.merge(other: b) { a, b in a + b }
        XCTAssertEqual(merged.count, 4)
    }

    func testMergeOverlappingKeys() {
        let a: TrieDictionary<Int> = ["apple": 1, "banana": 2, "cherry": 3]
        let b: TrieDictionary<Int> = ["apple": 10, "banana": 20, "date": 4]
        let merged = a.merge(other: b) { a, b in a + b }
        XCTAssertEqual(merged["apple"], 11)
        XCTAssertEqual(merged["banana"], 22)
        XCTAssertEqual(merged["cherry"], 3)
        XCTAssertEqual(merged["date"], 4)
    }

    func testMergeWithCommonPrefixes() {
        let a: TrieDictionary<String> = ["app": "application", "apple": "fruit", "apply": "action"]
        let b: TrieDictionary<String> = ["app": "program", "application": "software", "approximate": "rough"]
        let merged = a.merge(other: b) { a, b in "\(a)|\(b)" }
        XCTAssertEqual(merged.count, 5)
        XCTAssertEqual(merged["app"], "application|program")
        XCTAssertEqual(merged["apple"], "fruit")
        XCTAssertEqual(merged["application"], "software")
    }

    func testMergeCompressedPaths() {
        let a: TrieDictionary<Int> = ["uncompressed": 1]
        let b: TrieDictionary<Int> = ["uncommon": 2, "uncompressed": 10]
        let merged = a.merge(other: b) { a, b in a * b }
        XCTAssertEqual(merged["uncompressed"], 10)
        XCTAssertEqual(merged["uncommon"], 2)
        XCTAssertTrue(merged.isFullyCompressed)
    }

    func testMergeRootValues() {
        var a = TrieDictionary<String>()
        a[""] = "root1"
        a["child"] = "child1"
        var b = TrieDictionary<String>()
        b[""] = "root2"
        b["other"] = "other"
        let merged = a.merge(other: b) { a, b in "\(a)+\(b)" }
        XCTAssertEqual(merged[""], "root1+root2")
        XCTAssertEqual(merged["child"], "child1")
        XCTAssertEqual(merged["other"], "other")
    }

    func testMergeComplexStructure() {
        var a = TrieDictionary<Int>()
        a[""] = 0; a["a"] = 1; a["ab"] = 2; a["abc"] = 3; a["abd"] = 4; a["ac"] = 5; a["b"] = 6
        var b = TrieDictionary<Int>()
        b[""] = 100; b["a"] = 110; b["ab"] = 120; b["abe"] = 140; b["ac"] = 150; b["c"] = 160
        let merged = a.merge(other: b) { a, b in a + b }
        XCTAssertEqual(merged.count, 9)
        XCTAssertEqual(merged[""], 100)
        XCTAssertEqual(merged["a"], 111)
        XCTAssertEqual(merged["ab"], 122)
        XCTAssertEqual(merged["abc"], 3)
        XCTAssertEqual(merged["abe"], 140)
        XCTAssertEqual(merged["ac"], 155)
        XCTAssertTrue(merged.isFullyCompressed)
    }

    func testMergeDifferentRules() {
        let a: TrieDictionary<Int> = ["key1": 5, "key2": 10]
        let b: TrieDictionary<Int> = ["key1": 3, "key3": 7]
        XCTAssertEqual(a.merge(other: b) { a, b in max(a, b) }["key1"], 5)
        XCTAssertEqual(a.merge(other: b) { a, b in min(a, b) }["key1"], 3)
    }

    func testMergeResultIndependence() {
        var a: TrieDictionary<Int> = ["key": 1]
        var b: TrieDictionary<Int> = ["key": 2]
        let merged = a.merge(other: b) { a, b in a + b }
        a["key"] = 100
        b["key"] = 200
        XCTAssertEqual(merged["key"], 3)
    }

    // MARK: - Mutating merge(_:uniquingKeysWith:)

    func testMutatingMerge() {
        var a: TrieDictionary<Int> = ["a": 1, "b": 2]
        let b: TrieDictionary<Int> = ["b": 20, "c": 3]
        a.merge(b) { old, new in old + new }
        XCTAssertEqual(a["a"], 1)
        XCTAssertEqual(a["b"], 22)
        XCTAssertEqual(a["c"], 3)
    }

    // MARK: - merging(_:uniquingKeysWith:)

    func testMerging() {
        let a: TrieDictionary<String> = ["a": "hello", "b": "world"]
        let b: TrieDictionary<String> = ["b": "Swift", "c": "language"]
        let merged = a.merging(b) { _, new in new }
        XCTAssertEqual(merged["a"], "hello")
        XCTAssertEqual(merged["b"], "Swift")
        XCTAssertEqual(merged["c"], "language")
        XCTAssertEqual(a["b"], "world")
    }
}
