import XCTest
@testable import TrieDictionary

final class TraversalTests: XCTestCase {

    // MARK: - traverse()

    func testTraverseBasic() {
        var dict = TrieDictionary<Int>()
        dict["apple"] = 1
        dict["application"] = 2
        dict["apply"] = 3
        dict["banana"] = 4

        let sub = dict.traverse("app")
        XCTAssertEqual(sub.count, 3)
        XCTAssertEqual(sub["le"], 1)
        XCTAssertEqual(sub["lication"], 2)
        XCTAssertEqual(sub["ly"], 3)
        XCTAssertNil(sub["banana"])
    }

    func testTraverseExactMatch() {
        let dict: TrieDictionary<String> = ["hello": "world", "help": "me"]
        let sub = dict.traverse("hello")
        XCTAssertEqual(sub[""], "world")
    }

    func testTraverseNoMatch() {
        let dict: TrieDictionary<Int> = ["apple": 1, "banana": 2]
        let sub = dict.traverse("orange")
        XCTAssertTrue(sub.isEmpty)
    }

    func testTraverseEmptyPrefix() {
        let dict: TrieDictionary<String> = ["a": "first", "b": "second"]
        let sub = dict.traverse("")
        XCTAssertEqual(sub.count, 2)
    }

    func testTraversePartialPrefix() {
        var dict = TrieDictionary<Int>()
        dict["test"] = 1
        dict["testing"] = 2
        dict["tester"] = 3
        dict["tesla"] = 4

        let sub = dict.traverse("tes")
        XCTAssertEqual(sub.count, 4)
        XCTAssertEqual(sub["t"], 1)
        XCTAssertEqual(sub["ting"], 2)
        XCTAssertEqual(sub["ter"], 3)
        XCTAssertEqual(sub["la"], 4)
    }

    func testTraverseSingleCharPrefix() {
        let dict: TrieDictionary<String> = ["a": "alpha", "ab": "alphabet", "abc": "abcdef", "b": "beta"]
        let sub = dict.traverse("a")
        XCTAssertEqual(sub.count, 3)
        XCTAssertEqual(sub[""], "alpha")
        XCTAssertEqual(sub["b"], "alphabet")
        XCTAssertEqual(sub["bc"], "abcdef")
    }

    func testTraverseEmptyTrie() {
        let dict = TrieDictionary<Int>()
        XCTAssertTrue(dict.traverse("any").isEmpty)
    }

    func testTraversePrefixLongerThanKeys() {
        let dict: TrieDictionary<Int> = ["a": 1, "ab": 2]
        XCTAssertTrue(dict.traverse("abcdefg").isEmpty)
    }

    func testTraverseCompressedPathMismatch() {
        let dict: TrieDictionary<String> = ["application": "app", "appreciate": "thanks"]
        XCTAssertTrue(dict.traverse("approve").isEmpty)
    }

    func testTraversePreservesValueAtDestination() {
        let dict: TrieDictionary<String> = [
            "app": "application",
            "apple": "fruit",
            "application": "software",
            "apply": "action"
        ]
        let sub = dict.traverse("app")
        XCTAssertEqual(sub[""], "application")
        XCTAssertEqual(sub["le"], "fruit")
        XCTAssertEqual(sub["lication"], "software")
        XCTAssertEqual(sub["ly"], "action")
    }

    func testTraverseWithNoValueAtDestination() {
        let dict: TrieDictionary<String> = ["prefix_apple": "fruit", "prefix_tree": "plant"]
        let sub = dict.traverse("prefix_")
        XCTAssertNil(sub[""])
        XCTAssertEqual(sub["apple"], "fruit")
        XCTAssertEqual(sub["tree"], "plant")
    }

    // MARK: - subtrie()

    func testSubtrie() {
        let dict: TrieDictionary<Int> = ["apple": 1, "application": 2, "apply": 3, "banana": 4]
        let sub = dict.subtrie(at: "app")
        XCTAssertEqual(sub.count, 3)
        XCTAssertEqual(sub["le"], 1)
    }

    // MARK: - traverseChild()

    func testTraverseChildExisting() {
        let dict: TrieDictionary<String> = ["apple": "fruit", "application": "software", "banana": "yellow"]
        let child = dict.traverseChild("a")
        XCTAssertNotNil(child)
        XCTAssertEqual(child?.count, 2)
    }

    func testTraverseChildNonExistent() {
        let dict: TrieDictionary<String> = ["apple": "fruit"]
        XCTAssertNil(dict.traverseChild("b"))
    }

    func testTraverseChildEmpty() {
        let dict = TrieDictionary<String>()
        XCTAssertNil(dict.traverseChild("a"))
    }

    func testTraverseChildValueSemantics() {
        var dict = TrieDictionary<String>()
        dict["apple"] = "fruit"
        let child1 = dict.traverseChild("a")
        dict["application"] = "software"
        let child2 = dict.traverseChild("a")
        XCTAssertEqual(child1?.count, 1)
        XCTAssertEqual(child2?.count, 2)
    }

    // MARK: - traverseToNextChild()

    func testTraverseToNextChildBasic() {
        let dict: TrieDictionary<String> = ["apple": "fruit", "application": "software"]
        let result = dict.traverseToNextChild("a")
        XCTAssertNotNil(result)
        let (path, child) = result!
        XCTAssertEqual(path, "appl")
        XCTAssertEqual(child.count, 2)
        XCTAssertEqual(child["e"], "fruit")
        XCTAssertEqual(child["ication"], "software")
    }

    func testTraverseToNextChildNonExistent() {
        let dict: TrieDictionary<String> = ["apple": "fruit"]
        XCTAssertNil(dict.traverseToNextChild("b"))
    }

    func testTraverseToNextChildSingleKey() {
        let dict: TrieDictionary<String> = ["apple": "fruit"]
        let result = dict.traverseToNextChild("a")!
        XCTAssertEqual(result.0, "apple")
        XCTAssertEqual(result.1[""], "fruit")
    }

    func testTraverseToNextChildCompressedPath() {
        let dict: TrieDictionary<String> = ["application": "software", "appreciate": "thanks"]
        let result = dict.traverseToNextChild("a")!
        XCTAssertEqual(result.0, "app")
        XCTAssertEqual(result.1["lication"], "software")
        XCTAssertEqual(result.1["reciate"], "thanks")
    }

    func testTraverseToNextChildUnicode() {
        let dict: TrieDictionary<String> = ["cafe\u{0301}": "coffee", "\u{1F680}rocket": "space"]
        let result = dict.traverseToNextChild("c")!
        XCTAssertEqual(result.0, "cafe\u{0301}")
        XCTAssertEqual(result.1[""], "coffee")
    }

    // MARK: - getValuesAlongPath()

    func testGetValuesAlongPathBasic() {
        let dict: TrieDictionary<Int> = ["a": 1, "ab": 2, "abc": 3, "abcd": 4]
        XCTAssertEqual(dict.getValuesAlongPath("abcd"), [1, 2, 3, 4])
    }

    func testGetValuesAlongPathPartial() {
        let dict: TrieDictionary<String> = ["h": "start", "hel": "he", "hello": "h"]
        XCTAssertEqual(dict.getValuesAlongPath("hello"), ["start", "he", "h"])
    }

    func testGetValuesAlongPathNoMatch() {
        let dict: TrieDictionary<Int> = ["apple": 1, "banana": 2]
        XCTAssertEqual(dict.getValuesAlongPath("orange"), [])
    }

    func testGetValuesAlongPathEmpty() {
        let dict: TrieDictionary<Int> = ["a": 1]
        XCTAssertEqual(dict.getValuesAlongPath(""), [])
    }

    func testGetValuesAlongPathRootValueOrdering() {
        var dict = TrieDictionary<String>()
        dict[""] = "root"
        dict["a"] = "first"
        dict["ab"] = "second"
        XCTAssertEqual(dict.getValuesAlongPath("ab"), ["root", "first", "second"])
    }

    func testGetValuesAlongPathCompressed() {
        let dict: TrieDictionary<String> = ["app": "short", "application": "app", "apply": "verb"]
        XCTAssertEqual(dict.getValuesAlongPath("application"), ["short", "app"])
    }

    func testGetValuesAlongPathUnicode() {
        let dict: TrieDictionary<Int> = ["\u{1F680}": 1, "\u{1F680}\u{1F31F}": 2, "\u{1F680}\u{1F31F}\u{2B50}": 3]
        XCTAssertEqual(dict.getValuesAlongPath("\u{1F680}\u{1F31F}\u{2B50}"), [1, 2, 3])
    }

    func testGetValuesAlongPathLongerThanKeys() {
        let dict: TrieDictionary<Int> = ["ab": 1, "abc": 2]
        XCTAssertEqual(dict.getValuesAlongPath("abcdefgh"), [1, 2])
    }

    // MARK: - gatheringValuesAlongPaths()

    func testGatheringValuesAlongPaths() {
        let dict: TrieDictionary<Int> = ["a": 1, "ab": 2, "abc": 3, "b": 4]
        let gathered = dict.gatheringValuesAlongPaths(["abc", "ab", "xyz"])
        XCTAssertEqual(gathered["abc"], [1, 2, 3])
        XCTAssertEqual(gathered["ab"], [1, 2])
        XCTAssertNil(gathered["xyz"])
    }
}
