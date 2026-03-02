import XCTest
@testable import TrieDictionary

final class CoreOperationsTests: XCTestCase {

    // MARK: - Empty State

    func testEmptyDictionary() {
        let dict = TrieDictionary<Int>()
        XCTAssertTrue(dict.isEmpty)
        XCTAssertEqual(dict.count, 0)
        XCTAssertNil(dict["any"])
    }

    // MARK: - Insertion and Lookup

    func testInsertAndLookup() {
        var dict = TrieDictionary<Int>()
        dict["hello"] = 1
        XCTAssertFalse(dict.isEmpty)
        XCTAssertEqual(dict.count, 1)
        XCTAssertEqual(dict["hello"], 1)
    }

    func testMultipleInsertions() {
        var dict = TrieDictionary<Int>()
        dict["hello"] = 1
        dict["world"] = 2
        XCTAssertEqual(dict.count, 2)
        XCTAssertEqual(dict["hello"], 1)
        XCTAssertEqual(dict["world"], 2)
    }

    func testOverwriteExistingKey() {
        var dict = TrieDictionary<Int>()
        dict["hello"] = 1
        dict["hello"] = 10
        XCTAssertEqual(dict.count, 1)
        XCTAssertEqual(dict["hello"], 10)
    }

    func testPrefixedKeys() {
        var dict = TrieDictionary<Int>()
        dict["a"] = 1
        dict["ab"] = 2
        dict["abc"] = 3
        dict["abcd"] = 4
        dict["b"] = 5

        XCTAssertEqual(dict.count, 5)
        XCTAssertEqual(dict["a"], 1)
        XCTAssertEqual(dict["ab"], 2)
        XCTAssertEqual(dict["abc"], 3)
        XCTAssertEqual(dict["abcd"], 4)
        XCTAssertEqual(dict["b"], 5)
    }

    func testEmptyStringKey() {
        var dict = TrieDictionary<String>()
        dict[""] = "empty"
        dict["a"] = "letter"
        XCTAssertEqual(dict.count, 2)
        XCTAssertEqual(dict[""], "empty")
        XCTAssertEqual(dict["a"], "letter")

        dict[""] = nil
        XCTAssertEqual(dict.count, 1)
        XCTAssertNil(dict[""])
        XCTAssertEqual(dict["a"], "letter")
    }

    func testUnicodeKeys() {
        var dict = TrieDictionary<String>()
        dict["cafe\u{0301}"] = "coffee"
        dict["re\u{0301}sume\u{0301}"] = "cv"
        dict["\u{1F680}"] = "rocket"
        dict["\u{1F31F}"] = "star"

        XCTAssertEqual(dict.count, 4)
        XCTAssertEqual(dict["cafe\u{0301}"], "coffee")
        XCTAssertEqual(dict["re\u{0301}sume\u{0301}"], "cv")
        XCTAssertEqual(dict["\u{1F680}"], "rocket")
        XCTAssertEqual(dict["\u{1F31F}"], "star")
    }

    // MARK: - Update Value

    func testUpdateValueNewKey() {
        var dict = TrieDictionary<String>()
        let old = dict.updateValue("first", forKey: "key")
        XCTAssertNil(old)
        XCTAssertEqual(dict["key"], "first")
    }

    func testUpdateValueExistingKey() {
        var dict = TrieDictionary<String>()
        dict["key"] = "first"
        let old = dict.updateValue("second", forKey: "key")
        XCTAssertEqual(old, "first")
        XCTAssertEqual(dict["key"], "second")
    }

    // MARK: - Removal

    func testRemoveValue() {
        var dict = TrieDictionary<Int>()
        dict["a"] = 1
        dict["ab"] = 2
        dict["abc"] = 3

        let removed = dict.removeValue(forKey: "ab")
        XCTAssertEqual(removed, 2)
        XCTAssertEqual(dict.count, 2)
        XCTAssertNil(dict["ab"])
        XCTAssertEqual(dict["a"], 1)
        XCTAssertEqual(dict["abc"], 3)
    }

    func testRemoveNonExistentKey() {
        var dict = TrieDictionary<Int>()
        dict["a"] = 1
        let removed = dict.removeValue(forKey: "xyz")
        XCTAssertNil(removed)
        XCTAssertEqual(dict.count, 1)
    }

    func testRemoveSingleKey() {
        var dict = TrieDictionary<Int>()
        dict["key"] = 42
        dict.removeValue(forKey: "key")
        XCTAssertTrue(dict.isEmpty)
        XCTAssertEqual(dict.count, 0)
    }

    func testRemoveAll() {
        var dict = TrieDictionary<Int>()
        dict["a"] = 1
        dict["b"] = 2
        dict["c"] = 3
        dict.removeAll()
        XCTAssertTrue(dict.isEmpty)
        XCTAssertEqual(dict.count, 0)
    }

    func testRemoveAllClearsRootValue() {
        var dict = TrieDictionary<Int>()
        dict[""] = 42
        dict["hello"] = 1
        dict.removeAll()
        XCTAssertTrue(dict.isEmpty)
        XCTAssertEqual(dict.count, 0)
        XCTAssertNil(dict[""])
    }

    // MARK: - Keys and Values

    func testKeysAndValues() {
        var dict = TrieDictionary<String>()
        dict["apple"] = "fruit"
        dict["car"] = "vehicle"
        dict["book"] = "item"

        let keys = Set(dict.keys())
        let values = Set(dict.values())
        XCTAssertEqual(keys, Set(["apple", "car", "book"]))
        XCTAssertEqual(values, Set(["fruit", "vehicle", "item"]))
    }

    // MARK: - Child Characters

    func testGetAllChildCharacters() {
        var dict = TrieDictionary<String>()
        dict["apple"] = "fruit"
        dict["banana"] = "yellow"
        dict["cherry"] = "red"

        let chars = dict.getAllChildCharacters()
        XCTAssertEqual(Set(chars), Set(["a", "b", "c"]))
    }

    func testChildCharactersAfterRemoval() {
        var dict = TrieDictionary<String>()
        dict["apple"] = "fruit"
        dict["banana"] = "yellow"
        dict.removeValue(forKey: "banana")

        let chars = dict.getAllChildCharacters()
        XCTAssertEqual(chars.count, 1)
        XCTAssertTrue(chars.contains("a"))
        XCTAssertFalse(chars.contains("b"))
    }

    func testChildCharactersSharedPrefix() {
        var dict = TrieDictionary<String>()
        dict["apple"] = "fruit"
        dict["apricot"] = "orange"
        dict["application"] = "software"

        let chars = dict.getAllChildCharacters()
        XCTAssertEqual(chars.count, 1)
        XCTAssertTrue(chars.contains("a"))
    }
}
