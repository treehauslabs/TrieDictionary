import XCTest
@testable import TrieDictionary

final class ImmutableOperationsTests: XCTestCase {

    // MARK: - setting()

    func testSetting() {
        let original: TrieDictionary<Int> = ["a": 1, "b": 2]
        let updated = original.setting(key: "c", value: 3)
        XCTAssertEqual(original.count, 2)
        XCTAssertNil(original["c"])
        XCTAssertEqual(updated.count, 3)
        XCTAssertEqual(updated["c"], 3)
    }

    func testSettingOverwrite() {
        let original: TrieDictionary<String> = ["key": "old"]
        let updated = original.setting(key: "key", value: "new")
        XCTAssertEqual(original["key"], "old")
        XCTAssertEqual(updated["key"], "new")
    }

    func testSettingVariadic() {
        let original: TrieDictionary<Int> = ["a": 1]
        let updated = original.setting(("b", 2), ("c", 3), ("d", 4))
        XCTAssertEqual(original.count, 1)
        XCTAssertEqual(updated.count, 4)
    }

    func testSettingSequence() {
        let original: TrieDictionary<String> = ["x": "existing"]
        let pairs = [("a", "apple"), ("b", "banana")]
        let updated = original.setting(pairs)
        XCTAssertEqual(original.count, 1)
        XCTAssertEqual(updated.count, 3)
    }

    // MARK: - updatingValue()

    func testUpdatingValue() {
        let original: TrieDictionary<Int> = ["existing": 100]
        let (newDict, oldValue) = original.updatingValue(200, forKey: "existing")
        XCTAssertEqual(oldValue, 100)
        XCTAssertEqual(original["existing"], 100)
        XCTAssertEqual(newDict["existing"], 200)
    }

    func testUpdatingValueNewKey() {
        let original: TrieDictionary<Int> = ["a": 1]
        let (newDict, oldValue) = original.updatingValue(50, forKey: "new")
        XCTAssertNil(oldValue)
        XCTAssertEqual(newDict["new"], 50)
        XCTAssertEqual(original.count, 1)
    }

    // MARK: - removing()

    func testRemoving() {
        let original: TrieDictionary<String> = ["a": "apple", "b": "banana", "c": "cherry"]
        let updated = original.removing(key: "b")
        XCTAssertEqual(original.count, 3)
        XCTAssertEqual(updated.count, 2)
        XCTAssertNil(updated["b"])
    }

    func testRemovingVariadic() {
        let original: TrieDictionary<Int> = ["a": 1, "b": 2, "c": 3, "d": 4, "e": 5]
        let updated = original.removing("b", "d")
        XCTAssertEqual(original.count, 5)
        XCTAssertEqual(updated.count, 3)
    }

    func testRemovingSequence() {
        let original: TrieDictionary<String> = ["w": "water", "x": "xray", "y": "yellow", "z": "zebra"]
        let updated = original.removing(["x", "z"])
        XCTAssertEqual(updated.count, 2)
        XCTAssertEqual(updated["w"], "water")
        XCTAssertEqual(updated["y"], "yellow")
    }

    // MARK: - removingValue()

    func testRemovingValue() {
        let original: TrieDictionary<Int> = ["key": 42]
        let (updated, oldValue) = original.removingValue(forKey: "key")
        XCTAssertEqual(oldValue, 42)
        XCTAssertEqual(original["key"], 42)
        XCTAssertTrue(updated.isEmpty)
    }

    // MARK: - removingAll()

    func testRemovingAll() {
        let original: TrieDictionary<String> = ["a": "apple", "b": "banana"]
        let empty = original.removingAll()
        XCTAssertEqual(original.count, 2)
        XCTAssertTrue(empty.isEmpty)
    }

    func testRemovingAllWhere() {
        let original: TrieDictionary<Int> = ["a": 1, "b": 20, "c": 3, "d": 40, "e": 5]
        let filtered = original.removingAll { $0.value >= 10 }
        XCTAssertEqual(filtered.count, 3)
        XCTAssertNil(filtered["b"])
        XCTAssertNil(filtered["d"])
    }

    // MARK: - keepingOnly()

    func testKeepingOnly() {
        let original: TrieDictionary<String> = [
            "apple": "fruit", "carrot": "vegetable",
            "banana": "fruit", "broccoli": "vegetable"
        ]
        let fruits = original.keepingOnly { $0.value == "fruit" }
        XCTAssertEqual(fruits.count, 2)
        XCTAssertEqual(fruits["apple"], "fruit")
        XCTAssertEqual(fruits["banana"], "fruit")
    }

    // MARK: - Chaining

    func testFunctionalChaining() {
        let result = TrieDictionary<String>()
            .setting(key: "initial", value: "value")
            .setting(("a", "apple"), ("b", "banana"), ("c", "cherry"))
            .removing("b")
            .setting(key: "d", value: "date")
            .keepingOnly { $0.key != "initial" }
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result["a"], "apple")
        XCTAssertEqual(result["c"], "cherry")
        XCTAssertEqual(result["d"], "date")
    }

    func testOriginalUnmodifiedAfterChain() {
        let original: TrieDictionary<Int> = ["a": 1, "b": 2]
        let _ = original
            .setting(key: "c", value: 3)
            .removing(key: "a")
            .setting(("d", 4), ("e", 5))
        XCTAssertEqual(original.count, 2)
        XCTAssertEqual(original["a"], 1)
        XCTAssertEqual(original["b"], 2)
    }

    // MARK: - Empty Dictionary

    func testImmutableOpsOnEmpty() {
        let empty = TrieDictionary<Int>()
        let withValue = empty.setting(key: "test", value: 42)
        XCTAssertTrue(empty.isEmpty)
        XCTAssertEqual(withValue["test"], 42)

        let stillEmpty = empty.removing(key: "nonexistent")
        XCTAssertTrue(stillEmpty.isEmpty)
    }

    // MARK: - Traverse + Immutable Ops

    func testTraverseWithFunctionalOps() {
        let original: TrieDictionary<String> = [
            "apple": "fruit", "application": "software",
            "apply": "verb", "banana": "fruit"
        ]
        let result = original
            .setting(key: "approach", value: "method")
            .traverse("app")
            .keepingOnly { $0.value != "verb" }
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result["le"], "fruit")
        XCTAssertEqual(result["lication"], "software")
        XCTAssertEqual(result["roach"], "method")
        XCTAssertNil(result["ly"])
    }
}
