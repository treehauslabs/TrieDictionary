import XCTest
@testable import TrieDictionary

/// Real-world usage examples that also serve as documentation.
/// Each test demonstrates a practical use case for TrieDictionary.
final class UsageExampleTests: XCTestCase {

    // MARK: - Autocomplete / Search Suggestions

    /// Build an autocomplete engine where typing a prefix returns all matching entries.
    /// TrieDictionary.traverse() returns a subtrie in O(k) time — no scanning of all keys.
    func testAutocomplete() {
        var words = TrieDictionary<Int>()
        words["swift"] = 1
        words["swimming"] = 2
        words["swing"] = 3
        words["switch"] = 4
        words["symbol"] = 5
        words["system"] = 6

        // User types "sw" → find all completions
        let completions = words.traverse("sw")
        let keys = Set(completions.keys())
        XCTAssertEqual(keys, Set(["ift", "imming", "ing", "itch"]))

        // Narrow to "swi"
        let narrowed = words.traverse("swi")
        XCTAssertEqual(Set(narrowed.keys()), Set(["ft", "mming", "ng", "tch"]))

        // "sys" → only one match
        let sys = words.traverse("sys")
        XCTAssertEqual(sys.keys(), ["tem"])
    }

    // MARK: - Configuration Management

    /// Store hierarchical configuration using dot-separated keys.
    /// Use traverse() to pull out an entire config section as its own TrieDictionary.
    func testConfigurationManagement() {
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

        // Pull all database config
        let dbConfig = config.traverse("database.")
        XCTAssertEqual(dbConfig["host"], "localhost")
        XCTAssertEqual(dbConfig["port"], "5432")
        XCTAssertEqual(dbConfig["pool.min"], "2")
        XCTAssertEqual(dbConfig["pool.max"], "10")

        // Pull just the pool settings
        let poolConfig = config.traverse("database.pool.")
        XCTAssertEqual(poolConfig["min"], "2")
        XCTAssertEqual(poolConfig["max"], "10")
        XCTAssertEqual(poolConfig.count, 2)

        // Count config sections
        XCTAssertEqual(config.traverse("server.").count, 2)
        XCTAssertEqual(config.traverse("logging.").count, 2)
    }

    // MARK: - URL Routing

    /// Map URL path patterns to handler names.
    /// Use traverse() to get all routes under a path prefix,
    /// or direct lookup to resolve a specific route.
    func testURLRouting() {
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
        XCTAssertEqual(routes["/api/v1/users"], "listUsers")
        XCTAssertEqual(routes["/health"], "healthCheck")

        // Get all v1 user routes
        let userRoutes = routes.traverse("/api/v1/users")
        XCTAssertEqual(userRoutes.count, 3)
        XCTAssertEqual(userRoutes[""], "listUsers")
        XCTAssertEqual(userRoutes["/create"], "createUser")
        XCTAssertEqual(userRoutes["/delete"], "deleteUser")

        // Get all v1 routes
        let v1Routes = routes.traverse("/api/v1/")
        XCTAssertEqual(v1Routes.count, 5)

        // Get all v2 routes
        let v2Routes = routes.traverse("/api/v2/")
        XCTAssertEqual(v2Routes.count, 1)
    }

    // MARK: - Hierarchical Permissions (RBAC)

    /// Model role-based permissions with path inheritance.
    /// getValuesAlongPath() collects all permissions from root to a specific resource,
    /// naturally implementing permission inheritance.
    func testHierarchicalPermissions() {
        var permissions = TrieDictionary<String>()
        permissions["/"] = "authenticated"
        permissions["/admin"] = "admin_role"
        permissions["/admin/users"] = "user_manager"
        permissions["/admin/users/delete"] = "super_admin"

        // To access /admin/users/delete, check all required permissions along the path
        let required = permissions.getValuesAlongPath("/admin/users/delete")
        XCTAssertEqual(required, ["authenticated", "admin_role", "user_manager", "super_admin"])

        // /admin only needs the first two
        let adminPerms = permissions.getValuesAlongPath("/admin")
        XCTAssertEqual(adminPerms, ["authenticated", "admin_role"])
    }

    // MARK: - CSS / Style Cascading

    /// Simulate CSS-like style inheritance where child elements inherit parent styles.
    /// getValuesAlongPath() naturally collects all styles from root to a specific selector.
    func testStyleCascading() {
        var styles = TrieDictionary<[String: String]>()
        styles["body"] = ["font-family": "sans-serif", "color": "black"]
        styles["body.container"] = ["max-width": "1200px", "margin": "0 auto"]
        styles["body.container.header"] = ["background": "blue", "color": "white"]

        // Resolve all styles for a deeply nested element
        let headerStyles = styles.getValuesAlongPath("body.container.header")
        XCTAssertEqual(headerStyles.count, 3)
        XCTAssertEqual(headerStyles[0]["font-family"], "sans-serif")
        XCTAssertEqual(headerStyles[1]["max-width"], "1200px")
        XCTAssertEqual(headerStyles[2]["color"], "white")
    }

    // MARK: - Feature Flags with Namespaces

    /// Manage feature flags organized by team/service namespace.
    /// Use traverse() to get all flags for a team, withPrefix() to query without stripping.
    func testFeatureFlags() {
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
        XCTAssertEqual(paymentFlags.count, 3)
        XCTAssertEqual(paymentFlags["stripe_v2"], true)
        XCTAssertEqual(paymentFlags["refund_flow"], false)

        // Count enabled flags per team
        let enabledSearch = flags.traverse("search.").filter { $0.value == true }
        XCTAssertEqual(enabledSearch.count, 2)

        // Use withPrefix to keep original keys intact
        let authFlags = flags.withPrefix("auth.")
        XCTAssertEqual(authFlags["auth.oauth2"], true)
        XCTAssertEqual(authFlags["auth.passkeys"], false)
    }

    // MARK: - Dictionary-Like Operations

    /// TrieDictionary supports all the familiar operations from Swift's Dictionary.
    func testDictionaryLikeUsage() {
        // Dictionary literal initialization
        var inventory: TrieDictionary<Int> = [
            "apple": 50,
            "apricot": 30,
            "banana": 25,
            "blueberry": 100
        ]

        // Subscript get/set
        XCTAssertEqual(inventory["apple"], 50)
        inventory["cherry"] = 15
        XCTAssertEqual(inventory.count, 5)

        // Update with old value
        let old = inventory.updateValue(60, forKey: "apple")
        XCTAssertEqual(old, 50)

        // Remove with old value
        let removed = inventory.removeValue(forKey: "banana")
        XCTAssertEqual(removed, 25)
        XCTAssertNil(inventory["banana"])

        // Iterate
        var total = 0
        for (_, count) in inventory { total += count }
        XCTAssertEqual(total, 60 + 30 + 100 + 15) // apple + apricot + blueberry + cherry

        // map, filter, reduce via Collection conformance
        let doubled = inventory.mapValues { $0 * 2 }
        XCTAssertEqual(doubled["apple"], 120)

        let plenty = inventory.filter { $0.value >= 50 }
        XCTAssertEqual(plenty.count, 2) // apple=60, blueberry=100
    }

    // MARK: - Immutable Transformations

    /// TrieDictionary is a value type. Immutable APIs return new instances,
    /// leaving the original untouched — ideal for functional pipelines.
    func testImmutablePipeline() {
        let base: TrieDictionary<Int> = [
            "alice": 85,
            "bob": 92,
            "charlie": 78,
            "diana": 95,
            "eve": 88
        ]

        // Build a leaderboard: keep scores >= 85, add a namespace prefix
        let leaderboard = base
            .filter { $0.value >= 85 }
            .mapValues { "\($0) pts" }
            .addingPrefix("scores.")

        XCTAssertEqual(leaderboard["scores.alice"], "85 pts")
        XCTAssertEqual(leaderboard["scores.bob"], "92 pts")
        XCTAssertEqual(leaderboard["scores.diana"], "95 pts")
        XCTAssertEqual(leaderboard["scores.eve"], "88 pts")
        XCTAssertNil(leaderboard["scores.charlie"]) // filtered out (78 < 85)

        // Original is unchanged
        XCTAssertEqual(base.count, 5)
        XCTAssertEqual(base["charlie"], 78)
    }

    // MARK: - Merging Data Sources

    /// Merge two TrieDictionaries with a conflict-resolution strategy.
    /// Useful for combining data from multiple sources.
    func testMergingDataSources() {
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
        XCTAssertEqual(merged["settings.theme"], 2)       // remote wins
        XCTAssertEqual(merged["settings.fontSize"], 14)    // local only
        XCTAssertEqual(merged["settings.language"], 1)     // remote only
        XCTAssertEqual(merged["cache.ttl"], 600)           // remote wins

        // Or take the max
        let maxMerged = local.merging(remote) { a, b in max(a, b) }
        XCTAssertEqual(maxMerged["cache.ttl"], 600)
        XCTAssertEqual(maxMerged["settings.theme"], 2)
    }
}
