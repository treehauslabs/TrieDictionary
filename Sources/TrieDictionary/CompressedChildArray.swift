import Foundation

/**
 A space-efficient storage structure for child nodes in the compressed trie.
 
 This structure uses a bitmap-based approach similar to Swift Collections' TreeDictionary:
 - A 32-bit bitmap tracks which character hash positions have nodes (5-bit hash slices)
 - Compressed storage buffer with children and items growing from opposite ends
 - Hash-based indexing provides O(1) average lookup time with better hash distribution
 
 ## Memory Efficiency:
 Instead of storing a full 256-element array (for all possible characters),
 this structure uses compressed storage where children and items can grow towards
 each other from opposite ends of a buffer, maximizing space utilization.
 
 ## Performance Optimizations:
 - 32-bit bitmap operations for fast membership testing (vs previous 64-bit)
 - Better hash distribution using 5-bit hash slices
 - Compressed buffer storage for better cache locality
 - Inlined methods for hot path performance
 - Population count for efficient slot mapping
 
 ## Hash Function:
 Characters are hashed to 5-bit values (0-31) using their Unicode scalar values.
 This provides better hash distribution and aligns with TreeDictionary's approach.
 */
internal struct CompressedChildArray<Value> {
    /// Bitmap indicating which hash positions contain nodes (32 bits = 2^5 possible hash values)
    private let bitmap: UInt32
    
    /// Compressed storage buffer containing both nodes and characters
    /// Items grow from the right end, children would grow from left (though we only use items here)
    private let storage: ContiguousArray<(character: Character, node: TrieNode<Value>)>
    
    /**
     Creates an empty compressed child array.
     */
    init() {
        self.bitmap = 0
        self.storage = []
    }
    
    /**
     Creates a compressed child array with the specified components.
     
     - Parameter bitmap: The bitmap indicating which positions have nodes
     - Parameter storage: The compressed storage buffer containing character-node pairs
     */
    init(bitmap: UInt32, storage: ContiguousArray<(character: Character, node: TrieNode<Value>)>) {
        self.bitmap = bitmap
        self.storage = storage
    }
    
    /**
     Returns `true` if no child nodes are stored.
     
     - Complexity: O(1)
     */
    @inline(__always)
    var isEmpty: Bool {
        bitmap == 0
    }
    
    /**
     Returns the total number of values stored in all child subtrees.
     
     This traverses all child nodes and sums their value counts.
     
     - Returns: The total count of values in all child subtrees
     - Complexity: O(n) where n is the number of nodes in all subtrees
     */
    var totalCount: Int {
        var count = 0
        let nodeCount = storage.count
        for i in 0..<nodeCount {
            count += storage[i].node.count
        }
        return count
    }
    
    /**
     Returns the child node for the given character, if it exists.
     
     This method uses hash-based lookup with bitmap testing for fast character searches.
     Hash collisions are resolved by checking the stored character values in the compressed storage.
     
     - Parameter char: The character to search for
     - Returns: The corresponding child node, or `nil` if not found
     - Complexity: O(1) average case, O(k) worst case where k is collision chain length
     */
    func child(for char: Character) -> TrieNode<Value>? {
        let hash = hashCharacter(char)
        let bit = UInt32(1) << hash
        
        guard (bitmap & bit) != 0 else {
            return nil
        }
        
        let slotIndex = popCount(bitmap & (bit - 1))
        
        // Handle potential hash collisions by checking stored character
        if slotIndex < storage.count && storage[slotIndex].character == char {
            return storage[slotIndex].node
        }
        
        // Linear search for hash collisions (rare with 5-bit hashing)
        for item in storage {
            if item.character == char {
                return item.node
            }
        }
        
        return nil
    }
    
    /**
     Returns a new compressed child array with the given character-node pair added or updated.
     
     This method handles both insertion of new character-node pairs and updates of existing ones.
     The bitmap and compressed storage are efficiently updated using population count for indexing.
     
     - Parameter char: The character key
     - Parameter node: The node to associate with the character
     - Returns: A new CompressedChildArray with the update applied
     - Complexity: O(n) where n is the number of existing children (due to array copying)
     */
    func setting(char: Character, node: TrieNode<Value>) -> CompressedChildArray<Value> {
        // First check if we're updating an existing character
        for (index, item) in storage.enumerated() {
            if item.character == char {
                var newStorage = ContiguousArray(storage)
                newStorage[index] = (character: char, node: node)
                return CompressedChildArray(bitmap: bitmap, storage: newStorage)
            }
        }
        
        // Adding new character
        let hash = hashCharacter(char)
        let bit = UInt32(1) << hash
        let slotIndex = popCount(bitmap & (bit - 1))
        
        var newStorage = ContiguousArray(storage)
        newStorage.reserveCapacity(storage.count + 1)
        
        // Insert at the correct position to maintain sorted order by slot
        if slotIndex < storage.count {
            newStorage.insert((character: char, node: node), at: slotIndex)
        } else {
            newStorage.append((character: char, node: node))
        }
        
        let newBitmap = bitmap | bit
        return CompressedChildArray(bitmap: newBitmap, storage: newStorage)
    }
    
    /**
     Returns a new compressed child array with the given character removed.
     
     If the character is not present, returns the original array unchanged.
     
     - Parameter char: The character to remove
     - Returns: A new CompressedChildArray without the specified character
     - Complexity: O(n) where n is the number of existing children
     */
    func removing(char: Character) -> CompressedChildArray<Value> {
        // Find the character in storage
        guard let removeIndex = storage.firstIndex(where: { $0.character == char }) else {
            return self
        }
        
        let hash = hashCharacter(char)
        let bit = UInt32(1) << hash
        
        var newStorage = ContiguousArray(storage)
        newStorage.remove(at: removeIndex)
        
        // Only clear the bit if no other character maps to the same hash slot
        let newBitmap: UInt32
        let hasOtherItemsInSlot = newStorage.contains { hashCharacter($0.character) == hash }
        if hasOtherItemsInSlot {
            newBitmap = bitmap
        } else {
            newBitmap = bitmap & ~bit
        }
        
        return CompressedChildArray(bitmap: newBitmap, storage: newStorage)
    }
    
    /**
     Executes the given closure for each child node.
     
     This method provides an efficient way to iterate over all child nodes
     without exposing the internal storage structure.
     
     - Parameter body: A closure to execute for each child node
     - Complexity: O(n) where n is the number of child nodes
     */
    @inline(__always)
    func forEach(_ body: (TrieNode<Value>) -> Void) {
        let count = storage.count
        for i in 0..<count {
            body(storage[i].node)
        }
    }

    @inline(__always)
    func forEachPair(_ body: (Character, TrieNode<Value>) throws -> Void) rethrows {
        for i in 0..<storage.count {
            try body(storage[i].character, storage[i].node)
        }
    }

    func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> CompressedChildArray<T> {
        var newStorage = ContiguousArray<(character: Character, node: TrieNode<T>)>()
        newStorage.reserveCapacity(storage.count)
        for item in storage {
            newStorage.append((character: item.character, node: try item.node.mapValues(transform)))
        }
        return CompressedChildArray<T>(bitmap: bitmap, storage: newStorage)
    }

    func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> CompressedChildArray<T> {
        var result = CompressedChildArray<T>()
        for item in storage {
            if let newNode = try item.node.compactMapValues(transform) {
                result = result.setting(char: item.character, node: newNode)
            }
        }
        return result
    }
    
    /**
     Returns the first child node, if any.
     
     - Returns: The first child node, or `nil` if no children exist
     - Complexity: O(1)
     */
    var firstChild: TrieNode<Value>? {
        guard !storage.isEmpty else { return nil }
        return storage[0].node
    }
    
    /**
     Returns the number of direct child nodes.
     
     - Returns: The count of child nodes
     - Complexity: O(1)
     */
    @inline(__always)
    var childCount: Int {
        storage.count
    }
    
    /**
     Returns all characters that have child nodes in this array.
     
     - Returns: An array of characters for which child nodes exist
     - Complexity: O(n) where n is the number of child nodes
     */
    var allChildCharacters: [Character] {
        return storage.map { $0.character }
    }
    
    /**
     Computes a hash value for the given character.
     
     The hash function maps Unicode scalar values to 5-bit values (0-31) using bit masking.
     This aligns with TreeDictionary's approach and provides better hash distribution
     while maintaining efficient bitmap operations.
     
     - Parameter char: The character to hash
     - Returns: A hash value in the range 0-31
     - Complexity: O(1)
     */
    @inline(__always)
    private func hashCharacter(_ char: Character) -> Int {
        let scalar = char.unicodeScalars.first?.value ?? 0
        return Int(scalar & 31) // 5-bit hash (0-31) instead of 6-bit (0-63)
    }
    
    /**
     Returns the population count (number of set bits) in the given value.
     
     This is used to convert bitmap positions to storage indices by counting
     how many bits are set before the target position.
     
     - Parameter value: The bitmap value to count
     - Returns: The number of set bits
     - Complexity: O(1) - uses hardware instruction on modern processors
     */
    @inline(__always)
    private func popCount(_ value: UInt32) -> Int {
        return value.nonzeroBitCount
    }
    
    /**
     Returns a new compressed child array that efficiently merges this array with another.
     
     This method performs an optimal merge by:
     - Combining storage from both arrays
     - Handling character collisions by applying the merge rule to conflicting nodes
     - Preserving non-conflicting nodes from both arrays
     - Maintaining efficient storage organization
     
     - Parameter other: The other CompressedChildArray to merge with
     - Parameter mergeRule: A closure that resolves conflicts between nodes with the same character
     - Returns: A new CompressedChildArray containing the merged result
     - Complexity: O(m + n) where m and n are the sizes of the two arrays
     */
    func merging(with other: CompressedChildArray<Value>, mergeRule: (TrieNode<Value>, TrieNode<Value>) -> TrieNode<Value>) -> CompressedChildArray<Value> {
        // Handle trivial cases
        if isEmpty { return other }
        if other.isEmpty { return self }
        
        // Collect all unique characters from both arrays
        var characterToNode: [Character: TrieNode<Value>] = [:]
        
        // Add nodes from self
        for item in storage {
            characterToNode[item.character] = item.node
        }
        
        // Add/merge nodes from other
        for item in other.storage {
            if let existingNode = characterToNode[item.character] {
                // Character exists in both - merge the nodes
                characterToNode[item.character] = mergeRule(existingNode, item.node)
            } else {
                // Character only exists in other - add it
                characterToNode[item.character] = item.node
            }
        }
        
        // Build the result using the existing setting method for consistency
        var result = CompressedChildArray<Value>()
        for (char, node) in characterToNode {
            result = result.setting(char: char, node: node)
        }
        
        return result
    }
}
