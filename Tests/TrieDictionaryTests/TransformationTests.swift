import XCTest
@testable import TrieDictionary

final class TransformationTests: XCTestCase {

    // MARK: - mapValues

    func testMapValues() {
        let dict: TrieDictionary<Int> = ["a": 1, "b": 2, "c": 3]
        let mapped = dict.mapValues { $0 * 2 }
        XCTAssertEqual(mapped["a"], 2)
        XCTAssertEqual(mapped["b"], 4)
        XCTAssertEqual(mapped["c"], 6)
    }

    // MARK: - compactMapValues

    func testCompactMapValues() {
        let dict: TrieDictionary<Int> = ["a": 1, "b": 2, "c": 3, "d": 4]
        let mapped = dict.compactMapValues { $0 % 2 == 0 ? $0 : nil }
        XCTAssertEqual(mapped.count, 2)
        XCTAssertEqual(mapped["b"], 2)
        XCTAssertEqual(mapped["d"], 4)
        XCTAssertNil(mapped["a"])
    }

    // MARK: - filter

    func testFilter() {
        let dict: TrieDictionary<Int> = ["a": 1, "b": 2, "c": 3, "d": 4]
        let filtered = dict.filter { $0.value > 2 }
        XCTAssertEqual(filtered.count, 2)
        XCTAssertEqual(filtered["c"], 3)
        XCTAssertEqual(filtered["d"], 4)
    }

    // MARK: - filteringKeys / filteringValues

    func testFilteringKeys() {
        let dict: TrieDictionary<Int> = ["apple": 1, "application": 2, "banana": 3, "band": 4]
        let result = dict.filteringKeys { $0.hasPrefix("app") }
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result["apple"], 1)
        XCTAssertEqual(result["application"], 2)
    }

    func testFilteringValues() {
        let dict: TrieDictionary<Int> = ["a": 1, "b": 2, "c": 3, "d": 4]
        let result = dict.filteringValues { $0 % 2 == 0 }
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result["b"], 2)
        XCTAssertEqual(result["d"], 4)
    }

    // MARK: - mapKeys

    func testMapKeys() {
        let dict: TrieDictionary<String> = ["a": "alpha", "b": "beta"]
        let result = dict.mapKeys { $0.uppercased() }
        XCTAssertEqual(result["A"], "alpha")
        XCTAssertEqual(result["B"], "beta")
        XCTAssertNil(result["a"])
    }

    // MARK: - Prefix/Suffix Operations

    func testAddingPrefix() {
        let dict: TrieDictionary<Int> = ["apple": 1, "banana": 2]
        let result = dict.addingPrefix("fruit_")
        XCTAssertEqual(result["fruit_apple"], 1)
        XCTAssertEqual(result["fruit_banana"], 2)
        XCTAssertNil(result["apple"])
    }

    func testAddingPrefixSingleKey() {
        let dict: TrieDictionary<Int> = ["apple": 1]
        let result = dict.addingPrefix("my_")
        XCTAssertEqual(result["my_apple"], 1)
        XCTAssertNil(result["apple"])
    }

    func testAddingPrefixSharedPrefix() {
        let dict: TrieDictionary<Int> = ["apple": 1, "application": 2]
        let result = dict.addingPrefix("x_")
        XCTAssertEqual(result["x_apple"], 1)
        XCTAssertEqual(result["x_application"], 2)
        XCTAssertEqual(result.count, 2)
    }

    func testWithPrefix() {
        let dict: TrieDictionary<Int> = ["apple": 1, "application": 2, "banana": 3, "apply": 4]
        let result = dict.withPrefix("app")
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result["apple"], 1)
        XCTAssertEqual(result["application"], 2)
        XCTAssertEqual(result["apply"], 4)
        XCTAssertNil(result["banana"])
    }

    func testWithPrefixEmpty() {
        let dict: TrieDictionary<Int> = ["a": 1, "b": 2]
        XCTAssertEqual(dict.withPrefix("").count, 2)
    }

    func testWithPrefixNoMatch() {
        let dict: TrieDictionary<Int> = ["apple": 1]
        XCTAssertTrue(dict.withPrefix("xyz").isEmpty)
    }

    func testWithPrefixExactKey() {
        let dict: TrieDictionary<Int> = ["app": 1]
        let result = dict.withPrefix("app")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result["app"], 1)
    }

    func testWithSuffix() {
        let dict: TrieDictionary<String> = ["testing": "test", "running": "run", "swimming": "swim", "test": "t"]
        let result = dict.withSuffix("ing")
        XCTAssertEqual(result.count, 3)
        XCTAssertNil(result["test"])
    }

    func testMatching() {
        let dict: TrieDictionary<Int> = ["a": 1, "aa": 2, "aaa": 3, "b": 4]
        let result = dict.matching { $0.count == 1 }
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result["a"], 1)
        XCTAssertEqual(result["b"], 4)
    }

    // MARK: - Key Length Filtering

    func testFilteringKeyLength() {
        let dict: TrieDictionary<Int> = ["a": 1, "ab": 2, "abc": 3, "abcd": 4]
        XCTAssertEqual(dict.filteringKeyLength { $0 >= 3 }.count, 2)
    }

    func testWithMinKeyLength() {
        let dict: TrieDictionary<String> = ["a": "1", "ab": "2", "abc": "3"]
        let result = dict.withMinKeyLength(2)
        XCTAssertEqual(result.count, 2)
        XCTAssertNil(result["a"])
    }

    func testWithMaxKeyLength() {
        let dict: TrieDictionary<String> = ["a": "1", "ab": "2", "abc": "3"]
        let result = dict.withMaxKeyLength(2)
        XCTAssertEqual(result.count, 2)
        XCTAssertNil(result["abc"])
    }

    func testWithKeyLength() {
        let dict: TrieDictionary<Int> = ["a": 1, "ab": 2, "abc": 3, "abcd": 4]
        let result = dict.withKeyLength(3)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result["abc"], 3)
    }

    // MARK: - Partitioning

    func testPartitioned() {
        let dict: TrieDictionary<Int> = ["a": 1, "b": 2, "c": 3, "d": 4]
        let (evens, odds) = dict.partitioned { $0.value % 2 == 0 }
        XCTAssertEqual(evens.count, 2)
        XCTAssertEqual(evens["b"], 2)
        XCTAssertEqual(evens["d"], 4)
        XCTAssertEqual(odds.count, 2)
        XCTAssertEqual(odds["a"], 1)
        XCTAssertEqual(odds["c"], 3)
    }

    // MARK: - replacingValues

    func testReplacingValues() {
        let dict: TrieDictionary<String> = ["hello": "world", "foo": "bar"]
        let result = dict.replacingValues { key, value in key.count + value.count }
        XCTAssertEqual(result["hello"], 10)
        XCTAssertEqual(result["foo"], 6)
    }

    // MARK: - uniqueValues

    func testUniqueValues() {
        let dict: TrieDictionary<String> = ["a": "dup", "b": "unique", "c": "dup", "d": "another"]
        let result = dict.uniqueValues()
        XCTAssertEqual(result.count, 3)
    }

    // MARK: - transformAndFilter

    func testTransformAndFilter() {
        let dict: TrieDictionary<Int> = ["a": 1, "b": 2, "c": 3, "d": 4]
        let result: TrieDictionary<Int> = dict.transformAndFilter { elem in
            guard elem.value % 2 == 0 else { return nil }
            return (elem.key.uppercased(), elem.value * 2)
        }
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result["B"], 4)
        XCTAssertEqual(result["D"], 8)
    }

    // MARK: - Empty Dictionary Edge Cases

    func testTransformationsOnEmpty() {
        let dict = TrieDictionary<Int>()
        XCTAssertTrue(dict.withPrefix("test").isEmpty)
        XCTAssertTrue(dict.filteringKeys { _ in true }.isEmpty)
        XCTAssertTrue(dict.addingPrefix("prefix").isEmpty)
    }
}
