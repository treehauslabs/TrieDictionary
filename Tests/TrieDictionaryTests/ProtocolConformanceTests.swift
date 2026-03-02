import XCTest
@testable import TrieDictionary

final class ProtocolConformanceTests: XCTestCase {

    // MARK: - ExpressibleByDictionaryLiteral

    func testDictionaryLiteral() {
        let dict: TrieDictionary<String> = ["hello": "world", "foo": "bar"]
        XCTAssertEqual(dict.count, 2)
        XCTAssertEqual(dict["hello"], "world")
        XCTAssertEqual(dict["foo"], "bar")
    }

    // MARK: - CustomStringConvertible

    func testDescription() {
        let dict: TrieDictionary<Int> = ["a": 1, "b": 2]
        let desc = dict.description
        XCTAssertTrue(desc.contains("\"a\": 1"))
        XCTAssertTrue(desc.contains("\"b\": 2"))
    }

    // MARK: - CustomDebugStringConvertible

    func testDebugDescription() {
        let dict: TrieDictionary<Int> = ["a": 1]
        XCTAssertTrue(dict.debugDescription.hasPrefix("TrieDictionary("))
    }

    // MARK: - Equatable

    func testEquality() {
        let a: TrieDictionary<Int> = ["a": 1, "b": 2]
        let b: TrieDictionary<Int> = ["a": 1, "b": 2]
        XCTAssertEqual(a, b)
    }

    func testInequalityDifferentValues() {
        let a: TrieDictionary<Int> = ["a": 1, "b": 2]
        let b: TrieDictionary<Int> = ["a": 1, "b": 99]
        XCTAssertNotEqual(a, b)
    }

    func testInequalityDifferentCounts() {
        let a: TrieDictionary<Int> = ["a": 1, "b": 2]
        let b: TrieDictionary<Int> = ["a": 1]
        XCTAssertNotEqual(a, b)
    }

    func testEquatableInGenericContext() {
        let a: TrieDictionary<Int> = ["a": 1, "b": 2]
        let b: TrieDictionary<Int> = ["a": 1, "b": 2]
        func checkEquatable<T: Equatable>(_ x: T, _ y: T) -> Bool { x == y }
        XCTAssertTrue(checkEquatable(a, b))
    }

    // MARK: - Sequence (for-in)

    func testIteration() {
        let dict: TrieDictionary<Int> = ["one": 1, "two": 2, "three": 3]
        var pairs: [(String, Int)] = []
        for (key, value) in dict {
            pairs.append((key, value))
        }
        XCTAssertEqual(pairs.count, 3)
        let result = Dictionary(uniqueKeysWithValues: pairs)
        XCTAssertEqual(result["one"], 1)
        XCTAssertEqual(result["two"], 2)
        XCTAssertEqual(result["three"], 3)
    }

    // MARK: - Collection

    func testCollectionStartEndIndex() {
        let dict: TrieDictionary<Int> = ["a": 1, "b": 2]
        XCTAssertEqual(dict.startIndex, 0)
        XCTAssertEqual(dict.endIndex, 2)
    }

    func testCollectionSubscript() {
        let dict: TrieDictionary<Int> = ["a": 1, "b": 2]
        let elem = dict[dict.startIndex]
        XCTAssertNotNil(elem.key)
        XCTAssertNotNil(elem.value)
    }

    func testCollectionMap() {
        let dict: TrieDictionary<Int> = ["a": 1, "b": 2, "c": 3]
        let keys = dict.map { $0.key }
        XCTAssertEqual(Set(keys), Set(["a", "b", "c"]))
    }

    func testCollectionReduce() {
        let dict: TrieDictionary<Int> = ["a": 1, "b": 2, "c": 3]
        let sum = dict.reduce(0) { $0 + $1.value }
        XCTAssertEqual(sum, 6)
    }
}
