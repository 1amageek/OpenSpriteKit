// SKNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation

/// The base class of all SpriteKit nodes.
///
/// `SKNode` provides base properties for its subclasses and can be used as a container
/// or layout tool for other nodes. Nodes inherit the properties of their parent.
///
/// `SKNode` does not draw any content itself. Its visual counterparts include
/// `SKSpriteNode`, `SKShapeNode`, `SKLabelNode`, and other drawing nodes.
open class SKNode: @unchecked Sendable {

    // MARK: - Core Animation Layer Backing

    /// The backing CALayer for rendering.
    /// Subclasses can override `layerClass` to return a specialized layer type.
    public private(set) lazy var layer: CALayer = {
        let layer = type(of: self).layerClass.init()
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        return layer
    }()

    /// The class used to create the backing layer.
    /// Subclasses can override this to return a specialized layer type.
    open class var layerClass: CALayer.Type {
        return CALayer.self
    }

    // MARK: - Position and Transform Properties

    /// The position of the node in its parent's coordinate system.
    open var position: CGPoint = .zero {
        didSet {
            layer.position = position
        }
    }

    /// The height of the node relative to its parent.
    ///
    /// The default value is `0.0`. Nodes with a higher `zPosition` are rendered
    /// on top of nodes with a lower `zPosition`.
    open var zPosition: CGFloat = 0.0 {
        didSet {
            layer.zPosition = zPosition
        }
    }

    /// The Euler rotation about the z axis (in radians).
    ///
    /// The default value is `0.0`, which indicates no rotation.
    open var zRotation: CGFloat = 0.0 {
        didSet {
            updateLayerTransform()
        }
    }

    /// A scaling factor that multiplies the width of a node and its children.
    ///
    /// The default value is `1.0`.
    open var xScale: CGFloat = 1.0 {
        didSet {
            updateLayerTransform()
        }
    }

    /// A scaling factor that multiplies the height of a node and its children.
    ///
    /// The default value is `1.0`.
    open var yScale: CGFloat = 1.0 {
        didSet {
            updateLayerTransform()
        }
    }

    /// Updates the layer's transform based on current scale and rotation values.
    private func updateLayerTransform() {
        var transform = CATransform3DIdentity
        transform = CATransform3DScale(transform, xScale, yScale, 1.0)
        transform = CATransform3DRotate(transform, zRotation, 0, 0, 1)
        layer.transform = transform
    }

    // MARK: - Frame Properties

    /// A rectangle in the parent's coordinate system that contains the node's content,
    /// ignoring the node's children.
    ///
    /// The default implementation returns a rectangle with zero size at the node's position.
    open var frame: CGRect {
        return CGRect(origin: position, size: .zero)
    }

    /// A rectangle in the node's local coordinate system that defines its content area.
    ///
    /// Unlike `frame`, which is in the parent's coordinate system, `_contentBounds` is in the
    /// node's own coordinate system. The origin represents the offset from the node's
    /// position based on the anchor point, and the size represents the content dimensions.
    ///
    /// The default implementation returns a zero-sized rectangle at the origin.
    /// Subclasses should override this to return their actual content bounds.
    internal var _contentBounds: CGRect {
        return .zero
    }

    // MARK: - Node Tree Properties

    /// The scene node that contains this node.
    ///
    /// If the node is not in a scene, this property is `nil`.
    open internal(set) weak var scene: SKScene?

    /// The node's parent node.
    ///
    /// If the node has not been added to another node, this property is `nil`.
    open internal(set) weak var parent: SKNode?

    /// The node's children.
    open private(set) var children: [SKNode] = []

    /// The node's assignable name.
    ///
    /// Use the name property to identify nodes in the tree. Names do not need to be unique.
    open var name: String?

    // MARK: - Visibility Properties

    /// The transparency value applied to the node's contents.
    ///
    /// The default value is `1.0`, meaning fully opaque. A value of `0.0` means
    /// fully transparent.
    open var alpha: CGFloat = 1.0 {
        didSet {
            layer.opacity = Float(alpha)
        }
    }

    /// A Boolean value that determines whether a node and its descendants are rendered.
    ///
    /// The default value is `false`, meaning the node is visible.
    open var isHidden: Bool = false {
        didSet {
            layer.isHidden = isHidden
        }
    }

    // MARK: - Action Properties

    /// A speed modifier applied to all actions executed by a node and its descendants.
    ///
    /// The default value is `1.0`, which means actions run at normal speed.
    open var speed: CGFloat = 1.0

    /// A Boolean value that determines whether actions on the node and its descendants are processed.
    ///
    /// The default value is `false`, meaning actions are processed.
    open var isPaused: Bool = false

    /// Storage for actions with keys
    private var actionsByKey: [String: SKAction] = [:]

    /// Storage for anonymous actions
    private var anonymousActions: [SKAction] = []

    // MARK: - Physics Properties

    /// The physics body associated with the node.
    open var physicsBody: SKPhysicsBody?

    // MARK: - Constraint Properties

    /// A list of constraints to apply to the node.
    open var constraints: [SKConstraint]?

    /// The reach constraints to apply to the node when executing a reach action.
    open var reachConstraints: SKReachConstraints?

    // MARK: - User Interaction Properties

    /// A Boolean value that indicates whether the node receives touch events.
    ///
    /// The default value is `false`.
    open var isUserInteractionEnabled: Bool = false

    /// The focus behavior for a node.
    open var focusBehavior: SKNodeFocusBehavior = .none

    // MARK: - Custom Data

    /// A dictionary containing arbitrary data.
    ///
    /// Use this property to store custom data in a node without subclassing it.
    open var userData: [String: Any]?

    // MARK: - Initializers

    /// Initializes a blank node.
    public init() {
    }

    /// Creates a new node by loading an archive file from the game's main bundle.
    ///
    /// This method loads a node from a `.sks` file created in Xcode's SpriteKit Scene Editor
    /// or from a programmatically archived node.
    ///
    /// On WASM platforms, you must first register the file data with `SKResourceLoader`:
    /// ```swift
    /// SKResourceLoader.shared.registerScene(data: sksData, forName: "MyNode")
    /// let node = SKNode(fileNamed: "MyNode")
    /// ```
    ///
    /// - Parameter filename: The name of the archive file (without the `.sks` extension).
    /// - Returns: A new node loaded from the archive, or `nil` if the file could not be loaded.
    public convenience init?(fileNamed filename: String) {
        // Try to load from registered scene data first (WASM)
        if let data = SKResourceLoader.shared.sceneData(forName: filename) {
            if let node = Self.unarchive(from: data) as? Self {
                self.init()
                // Copy properties from loaded node
                self.copyProperties(from: node)
                return
            }
        }

        // Try to load from bundle (native platforms)
        let nameWithoutExtension = filename.hasSuffix(".sks") ? String(filename.dropLast(4)) : filename

        if let url = Bundle.main.url(forResource: nameWithoutExtension, withExtension: "sks") {
            if let data = try? Data(contentsOf: url),
               let node = Self.unarchive(from: data) as? Self {
                self.init()
                self.copyProperties(from: node)
                return
            }
        }

        // Fallback: return empty node
        self.init()
    }

    /// Creates a new node by loading an archive file with secure coding.
    ///
    /// - Parameters:
    ///   - filename: The name of the archive file (without the `.sks` extension).
    ///   - classes: A set of classes that are allowed to be unarchived.
    /// - Throws: An error if the archive could not be loaded.
    public convenience init(fileNamed filename: String, securelyWithClasses classes: Set<AnyHashable>) throws {
        // Try to load from registered scene data first (WASM)
        if let data = SKResourceLoader.shared.sceneData(forName: filename) {
            if let node = try Self.unarchiveSecurely(from: data, classes: classes) as? Self {
                self.init()
                self.copyProperties(from: node)
                return
            }
        }

        // Try to load from bundle (native platforms)
        let nameWithoutExtension = filename.hasSuffix(".sks") ? String(filename.dropLast(4)) : filename

        if let url = Bundle.main.url(forResource: nameWithoutExtension, withExtension: "sks"),
           let data = try? Data(contentsOf: url) {
            if let node = try Self.unarchiveSecurely(from: data, classes: classes) as? Self {
                self.init()
                self.copyProperties(from: node)
                return
            }
        }

        throw SKResourceError.notFound
    }

    /// Unarchives a node from data using SKSParser.
    private static func unarchive(from data: Data) -> SKNode? {
        // Use SKSParser for pure Swift parsing
        do {
            let scene = try SKSParser.parseScene(from: data)
            // If the root is not exactly what we want, return its first child or the scene itself
            if scene.children.count == 1 {
                return scene.children.first
            }
            return scene
        } catch {
            return nil
        }
    }

    /// Unarchives a node from data (classes parameter ignored in pure Swift implementation).
    private static func unarchiveSecurely(from data: Data, classes: Set<AnyHashable>) throws -> SKNode? {
        // Pure Swift implementation doesn't need class filtering
        return unarchive(from: data)
    }

    /// Copies properties from another node, including a deep copy of all children.
    ///
    /// This method delegates to `_copyNodeProperties(from:)` to ensure subclass-specific
    /// properties are also copied correctly during .sks file loading.
    internal func copyProperties(from node: SKNode) {
        self._copyNodeProperties(from: node)
    }

    // MARK: - Copying

    /// Creates a copy of this node, including all child nodes.
    ///
    /// - Returns: A new node with the same properties and a deep copy of all children.
    open func copy() -> SKNode {
        let nodeCopy = SKNode()
        nodeCopy._copyNodeProperties(from: self)
        return nodeCopy
    }

    /// Internal helper to copy SKNode properties.
    /// Subclasses override this to copy their specific properties.
    internal func _copyNodeProperties(from node: SKNode) {
        self.position = node.position
        self.zPosition = node.zPosition
        self.zRotation = node.zRotation
        self.xScale = node.xScale
        self.yScale = node.yScale
        self.alpha = node.alpha
        self.isHidden = node.isHidden
        self.speed = node.speed
        self.isPaused = node.isPaused
        self.name = node.name
        self.isUserInteractionEnabled = node.isUserInteractionEnabled
        self.focusBehavior = node.focusBehavior
        self.userData = node.userData
        self.physicsBody = node.physicsBody?.copy()
        self.constraints = node.constraints?.map { $0.copy() }
        self.reachConstraints = node.reachConstraints

        // Deep copy all children
        for child in node.children {
            self.addChild(child.copy())
        }
    }

    // MARK: - Scaling

    /// Sets the `xScale` and `yScale` properties of the node.
    ///
    /// - Parameter scale: The new scale value for both axes.
    open func setScale(_ scale: CGFloat) {
        xScale = scale
        yScale = scale
    }

    /// Returns a rectangle in the parent's coordinate system that contains the position
    /// and size of itself and all child nodes.
    ///
    /// - Returns: The accumulated frame of the node and its children.
    open func calculateAccumulatedFrame() -> CGRect {
        var accumulated = frame  // In parent's coordinate system
        for child in children {
            // child.calculateAccumulatedFrame() returns in THIS node's local coordinate system
            // (child's parent = this node). We need to transform it to this node's parent
            // coordinate system using this node's transform (position, scale, rotation).
            let childAccumInLocal = child.calculateAccumulatedFrame()
            let childAccumInParent = transformRectToParent(childAccumInLocal)
            accumulated = accumulated.union(childAccumInParent)
        }
        return accumulated
    }

    /// Transforms a child's frame to this node's coordinate system,
    /// accounting for the child's position, scale, and rotation.
    private func transformChildFrame(_ rect: CGRect, child: SKNode) -> CGRect {
        // If no rotation, just apply position and scale
        if child.zRotation == 0 {
            let scaledWidth = rect.width * abs(child.xScale)
            let scaledHeight = rect.height * abs(child.yScale)
            let scaledX = rect.origin.x * child.xScale
            let scaledY = rect.origin.y * child.yScale
            return CGRect(
                x: scaledX + child.position.x,
                y: scaledY + child.position.y,
                width: scaledWidth,
                height: scaledHeight
            )
        }

        // With rotation, we need to transform all four corners and compute AABB
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY)
        ]

        let cosAngle = cos(child.zRotation)
        let sinAngle = sin(child.zRotation)

        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude

        for corner in corners {
            // Apply scale
            let scaledX = corner.x * child.xScale
            let scaledY = corner.y * child.yScale

            // Apply rotation
            let rotatedX = scaledX * cosAngle - scaledY * sinAngle
            let rotatedY = scaledX * sinAngle + scaledY * cosAngle

            // Apply position
            let finalX = rotatedX + child.position.x
            let finalY = rotatedY + child.position.y

            minX = min(minX, finalX)
            minY = min(minY, finalY)
            maxX = max(maxX, finalX)
            maxY = max(maxY, finalY)
        }

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    // MARK: - Node Tree Modification

    /// Adds a node to the end of the receiver's list of child nodes.
    ///
    /// If the node already has a parent, it is removed from that parent before being added.
    ///
    /// - Parameter node: The node to add as a child.
    open func addChild(_ node: SKNode) {
        // Remove from existing parent if any (per SpriteKit spec)
        if node.parent != nil {
            node.removeFromParent()
        }
        node.parent = self
        node.scene = self.scene ?? (self as? SKScene)
        children.append(node)
        // Sync layer hierarchy
        layer.addSublayer(node.layer)
        propagateSceneToChildren(node)
    }

    /// Inserts a node into a specific position in the receiver's list of child nodes.
    ///
    /// If the node already has a parent, it is removed from that parent before being inserted.
    ///
    /// - Parameters:
    ///   - node: The node to insert.
    ///   - index: The index at which to insert the node.
    open func insertChild(_ node: SKNode, at index: Int) {
        // Remove from existing parent if any (per SpriteKit spec)
        if node.parent != nil {
            node.removeFromParent()
        }
        node.parent = self
        node.scene = self.scene ?? (self as? SKScene)
        children.insert(node, at: index)
        // Sync layer hierarchy
        layer.insertSublayer(node.layer, at: UInt32(index))
        propagateSceneToChildren(node)
    }

    /// Removes the receiving node from its parent.
    open func removeFromParent() {
        guard let parent = parent else { return }
        parent.children.removeAll { $0 === self }
        // Sync layer hierarchy
        layer.removeFromSuperlayer()
        self.parent = nil
        self.scene = nil
        clearSceneFromChildren()
    }

    /// Removes all of the node's children.
    open func removeAllChildren() {
        for child in children {
            child.parent = nil
            child.scene = nil
            // Sync layer hierarchy
            child.layer.removeFromSuperlayer()
            child.clearSceneFromChildren()
        }
        children.removeAll()
    }

    /// Removes a list of children from the receiving node.
    ///
    /// - Parameter nodes: The nodes to remove.
    open func removeChildren(in nodes: [SKNode]) {
        for node in nodes {
            if node.parent === self {
                node.removeFromParent()
            }
        }
    }

    /// Moves the node to a new parent node in the scene.
    ///
    /// - Parameter parent: The new parent node.
    open func move(toParent parent: SKNode) {
        removeFromParent()
        parent.addChild(self)
    }

    /// Returns a Boolean value that indicates whether the node is a descendant of the target node.
    ///
    /// - Parameter parent: The node to check against.
    /// - Returns: `true` if this node is in the parent hierarchy of the target node.
    open func inParentHierarchy(_ parent: SKNode) -> Bool {
        var current: SKNode? = self
        while let node = current {
            if node === parent {
                return true
            }
            current = node.parent
        }
        return false
    }

    /// Compares the parameter node to the receiving node.
    ///
    /// - Parameter node: The node to compare.
    /// - Returns: `true` if the nodes are equal.
    open func isEqual(to node: SKNode) -> Bool {
        return self === node
    }

    // MARK: - Private Helpers for Scene Propagation

    private func propagateSceneToChildren(_ node: SKNode) {
        let targetScene = self.scene ?? (self as? SKScene)
        node.scene = targetScene
        for child in node.children {
            propagateSceneToChildren(child)
        }
    }

    private func clearSceneFromChildren() {
        for child in children {
            child.scene = nil
            child.clearSceneFromChildren()
        }
    }

    // MARK: - Node Search

    /// Searches the children of the receiving node for a node with a specific name.
    ///
    /// - Parameter name: The name to search for.
    /// - Returns: The first child node with the specified name, or `nil` if not found.
    open func childNode(withName name: String) -> SKNode? {
        // Simple search (non-path based, no special characters)
        if !name.contains("/") && !name.contains("*") && !name.contains(".") && !name.contains("[") {
            return children.first { $0.name == name }
        }
        // For pattern-based searches, use the subscript operator
        return self[name].first
    }

    // MARK: - Pattern Matching Helpers

    /// Checks if a pattern contains character class syntax (e.g., `[0-9]` or `[a,b,c]`).
    private func containsCharacterClass(_ pattern: String) -> Bool {
        return pattern.contains("[") && pattern.contains("]")
    }

    /// Matches a node name against a pattern that may contain character classes.
    ///
    /// Character class syntax:
    /// - `[0-9]` matches any single digit (range)
    /// - `[a,b,c]` matches 'a', 'b', or 'c' (comma-separated)
    /// - `[a-z]` matches any lowercase letter (range)
    ///
    /// - Parameters:
    ///   - name: The node name to test.
    ///   - pattern: The pattern to match against.
    /// - Returns: `true` if the name matches the pattern.
    private func matchesPattern(_ name: String?, pattern: String) -> Bool {
        guard let name = name else { return false }

        // Handle wildcard
        if pattern == "*" {
            return true
        }

        // No character class - exact match required
        guard containsCharacterClass(pattern) else {
            return name == pattern
        }

        // Parse and match pattern with character classes
        return matchPatternWithCharacterClass(name: name, pattern: pattern)
    }

    /// Matches a name against a pattern containing character class syntax.
    private func matchPatternWithCharacterClass(name: String, pattern: String) -> Bool {
        var nameIndex = name.startIndex
        var patternIndex = pattern.startIndex

        while patternIndex < pattern.endIndex && nameIndex < name.endIndex {
            let patternChar = pattern[patternIndex]

            if patternChar == "[" {
                // Find the closing bracket
                guard let closeBracket = pattern[patternIndex...].firstIndex(of: "]") else {
                    return false // Invalid pattern
                }

                // Extract the character class content
                let classStart = pattern.index(after: patternIndex)
                let classContent = String(pattern[classStart..<closeBracket])

                // Get the character to match
                let charToMatch = name[nameIndex]

                // Check if the character matches the class
                if !characterMatchesClass(charToMatch, classContent: classContent) {
                    return false
                }

                // Move past the character class in pattern and one character in name
                patternIndex = pattern.index(after: closeBracket)
                nameIndex = name.index(after: nameIndex)
            } else if patternChar == "*" {
                // Wildcard matches any remaining characters
                return true
            } else {
                // Exact character match
                if patternChar != name[nameIndex] {
                    return false
                }
                patternIndex = pattern.index(after: patternIndex)
                nameIndex = name.index(after: nameIndex)
            }
        }

        // Both must be exhausted for a full match
        return patternIndex == pattern.endIndex && nameIndex == name.endIndex
    }

    /// Checks if a character matches a character class specification.
    ///
    /// - Parameters:
    ///   - char: The character to test.
    ///   - classContent: The content inside the brackets (e.g., "0-9" or "a,b,c").
    /// - Returns: `true` if the character matches.
    private func characterMatchesClass(_ char: Character, classContent: String) -> Bool {
        // Handle comma-separated values
        if classContent.contains(",") {
            let values = classContent.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            return values.contains(String(char))
        }

        // Handle range syntax (e.g., "0-9", "a-z")
        if classContent.contains("-") && classContent.count >= 3 {
            let parts = classContent.split(separator: "-", maxSplits: 1)
            if parts.count == 2,
               let startChar = parts[0].first,
               let endChar = parts[1].first {
                return char >= startChar && char <= endChar
            }
        }

        // Single character or list of characters without commas
        return classContent.contains(char)
    }

    /// Searches the children of the receiving node to perform processing for nodes that share a name.
    ///
    /// - Parameters:
    ///   - name: The name to search for (supports path notation and character classes).
    ///   - block: A block to execute for each found node. Set `stop` to `true` to stop enumeration.
    open func enumerateChildNodes(withName name: String, using block: (SKNode, UnsafeMutablePointer<ObjCBool>) -> Void) {
        var stop = ObjCBool(false)

        // Optimize for simple name search (most common case)
        if !name.contains("/") && !name.contains("*") && !name.contains(".") && !name.contains("[") {
            for child in children {
                if child.name == name {
                    block(child, &stop)
                    if stop.boolValue {
                        return
                    }
                }
            }
            return
        }

        // For complex patterns, use the subscript but with early termination
        enumerateNodesWithPattern(name, from: self, stop: &stop, block: block)
    }

    /// Internal helper for lazy enumeration with pattern matching
    private func enumerateNodesWithPattern(_ pattern: String, from root: SKNode, stop: inout ObjCBool, block: (SKNode, UnsafeMutablePointer<ObjCBool>) -> Void) {
        if stop.boolValue { return }

        // Handle special cases
        if pattern == "." {
            block(root, &stop)
            return
        }
        if pattern == ".." {
            if let parent = root.parent {
                block(parent, &stop)
            }
            return
        }

        // Handle recursive search
        if pattern.hasPrefix("//") {
            let subpattern = String(pattern.dropFirst(2))
            // Split the subpattern into components for path-based recursive search
            // e.g., "//node/child" should find all "node" descendants, then search for "child" in each
            let components = subpattern.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
            if components.isEmpty {
                return
            }
            enumerateAllDescendantsWithPath(root: root, components: components, stop: &stop, block: block)
            return
        }

        // Handle path-based search
        let components = pattern.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        enumerateWithComponents(components, from: root, stop: &stop, block: block)
    }

    private func enumerateAllDescendantsWithPath(root: SKNode, components: [String], stop: inout ObjCBool, block: (SKNode, UnsafeMutablePointer<ObjCBool>) -> Void) {
        guard !components.isEmpty else { return }
        if stop.boolValue { return }

        let firstPattern = components[0]
        let remainingComponents = Array(components.dropFirst())

        func findMatchingDescendants(from node: SKNode) {
            if stop.boolValue { return }

            for child in node.children {
                if stop.boolValue { return }

                if matchesPattern(child.name, pattern: firstPattern) {
                    if remainingComponents.isEmpty {
                        // No more components, this is a final match
                        block(child, &stop)
                        if stop.boolValue { return }
                    } else {
                        // Continue searching from this node with remaining components
                        enumerateWithComponents(remainingComponents, from: child, stop: &stop, block: block)
                        if stop.boolValue { return }
                    }
                }
                // Continue searching deeper in the tree
                findMatchingDescendants(from: child)
            }
        }

        findMatchingDescendants(from: root)
    }

    private func enumerateWithComponents(_ components: [String], from node: SKNode, stop: inout ObjCBool, block: (SKNode, UnsafeMutablePointer<ObjCBool>) -> Void) {
        if stop.boolValue { return }
        guard !components.isEmpty else { return }

        var remaining = components
        let first = remaining.removeFirst()

        // Handle leading "/" - empty first component means "start from this node"
        // e.g., "/foo" splits to ["", "foo"], so skip empty and search children for "foo"
        if first.isEmpty {
            if remaining.isEmpty {
                return
            }
            enumerateWithComponents(remaining, from: node, stop: &stop, block: block)
            return
        }

        if remaining.isEmpty {
            // Last component - call block for matches
            if first == "*" {
                for child in node.children {
                    if stop.boolValue { return }
                    block(child, &stop)
                }
            } else if first == "." {
                block(node, &stop)
            } else if first == "..", let parent = node.parent {
                block(parent, &stop)
            } else {
                for child in node.children {
                    if stop.boolValue { return }
                    if matchesPattern(child.name, pattern: first) {
                        block(child, &stop)
                    }
                }
            }
        } else {
            // More components - recurse
            if first == "*" {
                for child in node.children {
                    if stop.boolValue { return }
                    enumerateWithComponents(remaining, from: child, stop: &stop, block: block)
                }
            } else if first == "." {
                enumerateWithComponents(remaining, from: node, stop: &stop, block: block)
            } else if first == "..", let parent = node.parent {
                enumerateWithComponents(remaining, from: parent, stop: &stop, block: block)
            } else {
                for child in node.children {
                    if stop.boolValue { return }
                    if matchesPattern(child.name, pattern: first) {
                        enumerateWithComponents(remaining, from: child, stop: &stop, block: block)
                    }
                }
            }
        }
    }

    /// Returns an array of nodes that match the name parameter.
    ///
    /// The name parameter supports the following search syntax:
    /// - Simple name: Matches children with that exact name
    /// - `/`: Separator for path components
    /// - `//`: Searches all descendants
    /// - `*`: Wildcard for any name
    /// - `.`: Current node
    /// - `..`: Parent node
    /// - `[0-9]`: Character class matching a range
    /// - `[a,b,c]`: Character class matching specific characters
    ///
    /// - Parameter name: The search string.
    /// - Returns: An array of matching nodes.
    open subscript(name: String) -> [SKNode] {
        return searchNodes(pattern: name, from: self)
    }

    private func searchNodes(pattern: String, from root: SKNode) -> [SKNode] {
        // Handle special cases
        if pattern == "." {
            return [root]
        }
        if pattern == ".." {
            return root.parent != nil ? [root.parent!] : []
        }

        // Handle recursive search
        if pattern.hasPrefix("//") {
            let subpattern = String(pattern.dropFirst(2))
            // Split the subpattern into components for path-based recursive search
            // e.g., "//node/child" should find all "node" descendants, then search for "child" in each
            let components = subpattern.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
            if components.isEmpty {
                return []
            }
            return searchAllDescendantsWithPath(root: root, components: components)
        }

        // Handle path-based search
        let components = pattern.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        return searchWithComponents(components, from: root)
    }

    private func searchWithComponents(_ components: [String], from node: SKNode) -> [SKNode] {
        guard !components.isEmpty else { return [] }

        var current = components
        let first = current.removeFirst()

        // Handle leading "/" - empty first component means "start from this node"
        // e.g., "/foo" splits to ["", "foo"], so skip empty and search children for "foo"
        if first.isEmpty {
            if current.isEmpty {
                return []
            }
            return searchWithComponents(current, from: node)
        }

        var matches: [SKNode] = []

        if first == "*" {
            matches = node.children
        } else if first == "." {
            matches = [node]
        } else if first == ".." {
            if let parent = node.parent {
                matches = [parent]
            }
        } else {
            matches = node.children.filter { matchesPattern($0.name, pattern: first) }
        }

        if current.isEmpty {
            return matches
        }

        return matches.flatMap { searchWithComponents(current, from: $0) }
    }

    private func searchAllDescendantsWithPath(root: SKNode, components: [String]) -> [SKNode] {
        guard !components.isEmpty else { return [] }

        var results: [SKNode] = []
        let firstPattern = components[0]
        let remainingComponents = Array(components.dropFirst())

        func findMatchingDescendants(from node: SKNode) {
            for child in node.children {
                if matchesPattern(child.name, pattern: firstPattern) {
                    if remainingComponents.isEmpty {
                        // No more components, this is a final match
                        results.append(child)
                    } else {
                        // Continue searching from this node with remaining components
                        let subResults = searchWithComponents(remainingComponents, from: child)
                        results.append(contentsOf: subResults)
                    }
                }
                // Continue searching deeper in the tree
                findMatchingDescendants(from: child)
            }
        }

        findMatchingDescendants(from: root)
        return results
    }

    // MARK: - Actions

    /// Adds an action to the list of actions executed by the node.
    ///
    /// - Parameter action: The action to run.
    open func run(_ action: SKAction) {
        anonymousActions.append(action)
        SKActionRunner.shared.runAction(action, on: self)
    }

    /// Adds an action to the list of actions executed by the node and schedules
    /// the argument block to be run upon completion of the action.
    ///
    /// - Parameters:
    ///   - action: The action to run.
    ///   - completion: A block to execute when the action completes.
    open func run(_ action: SKAction, completion: @escaping () -> Void) {
        anonymousActions.append(action)
        SKActionRunner.shared.runAction(action, on: self, completion: completion)
    }

    /// Adds an identifiable action to the list of actions executed by the node.
    ///
    /// - Parameters:
    ///   - action: The action to run.
    ///   - key: A unique key used to identify the action.
    open func run(_ action: SKAction, withKey key: String) {
        actionsByKey[key] = action
        SKActionRunner.shared.runAction(action, on: self, withKey: key)
    }

    /// Returns an action associated with a specific key.
    ///
    /// - Parameter key: The key of the action to retrieve.
    /// - Returns: The action associated with the key, or `nil` if not found.
    open func action(forKey key: String) -> SKAction? {
        return actionsByKey[key]
    }

    /// Returns a Boolean value that indicates whether the node is executing actions.
    ///
    /// - Returns: `true` if the node has any running actions.
    open func hasActions() -> Bool {
        return !actionsByKey.isEmpty || !anonymousActions.isEmpty
    }

    /// Ends and removes all actions from the node.
    open func removeAllActions() {
        actionsByKey.removeAll()
        anonymousActions.removeAll()
        SKActionRunner.shared.removeAllActions(from: self)
    }

    /// Removes an action associated with a specific key.
    ///
    /// - Parameter key: The key of the action to remove.
    open func removeAction(forKey key: String) {
        actionsByKey.removeValue(forKey: key)
        SKActionRunner.shared.removeAction(forKey: key, from: self)
    }

    // MARK: - Hit Testing

    /// Returns a Boolean value that indicates whether a point lies inside the parent's coordinate system.
    ///
    /// - Parameter p: A point in the parent's coordinate system.
    /// - Returns: `true` if the point is inside the node's frame.
    ///
    /// This method performs a simple geometric test using the node's `frame` property,
    /// which is in the parent's coordinate system. It does not check visibility or
    /// user interaction state—those checks are performed by `atPoint(_:)` and `nodes(at:)`.
    open func contains(_ p: CGPoint) -> Bool {
        return frame.contains(p)
    }

    /// Returns the deepest visible descendant that intersects a point.
    ///
    /// - Parameter p: A point in the node's coordinate system.
    /// - Returns: The deepest hittable descendant at the point, or this node if no hittable descendants are found.
    ///
    /// A node is hittable if:
    /// - Its accumulated alpha > 0 (product of all ancestor alphas)
    /// - It is not hidden (and no ancestor is hidden)
    /// - Its own isUserInteractionEnabled is true
    open func atPoint(_ p: CGPoint) -> SKNode {
        // If this node is invisible, entire subtree is invisible - return self
        if isHidden || alpha == 0 { return self }

        // Search with accumulated alpha (visibility propagates through ancestors)
        if let result = atPointHelper(p, accumulatedAlpha: alpha) {
            return result
        }

        // No hittable descendant found - return self only if self is hittable
        if _contentBounds.contains(p) && isUserInteractionEnabled {
            return self
        }

        // Nothing hittable at point - return self as fallback (standard SpriteKit behavior)
        return self
    }

    /// Internal helper for atPoint that tracks accumulated properties.
    private func atPointHelper(_ p: CGPoint, accumulatedAlpha: CGFloat) -> SKNode? {
        // Search children in reverse order (top-most first)
        for child in children.reversed() {
            // Skip hidden children
            if child.isHidden { continue }

            // Calculate effective properties for this child
            let childEffectiveAlpha = accumulatedAlpha * child.alpha

            // Skip if effectively invisible
            if childEffectiveAlpha == 0 { continue }

            let childPoint = convertPointToChild(p, child: child)

            // Recurse into child's subtree
            if let result = child.atPointHelper(childPoint, accumulatedAlpha: childEffectiveAlpha) {
                return result
            }

            // Check if this child itself is hittable
            if child._contentBounds.contains(childPoint) && child.isUserInteractionEnabled {
                return child
            }
        }

        return nil
    }

    /// Converts a point from this node's coordinate system to a child's coordinate system.
    /// Applies inverse transforms (position, rotation, scale) in the correct order.
    private func convertPointToChild(_ point: CGPoint, child: SKNode) -> CGPoint {
        // First, translate to child's local origin
        var result = CGPoint(x: point.x - child.position.x, y: point.y - child.position.y)

        // Apply inverse rotation
        if child.zRotation != 0 {
            let cosAngle = cos(-child.zRotation)
            let sinAngle = sin(-child.zRotation)
            let rotatedX = result.x * cosAngle - result.y * sinAngle
            let rotatedY = result.x * sinAngle + result.y * cosAngle
            result.x = rotatedX
            result.y = rotatedY
        }

        // Apply inverse scale
        if child.xScale != 0 {
            result.x /= child.xScale
        }
        if child.yScale != 0 {
            result.y /= child.yScale
        }

        return result
    }

    /// Returns an array of all visible descendants that intersect a point.
    ///
    /// The array is sorted in reverse drawing order (topmost node first).
    ///
    /// - Parameter p: A point in the node's coordinate system.
    /// - Returns: An array of nodes at the specified point, sorted with topmost first.
    ///
    /// A node is hittable if:
    /// - Its accumulated alpha > 0 (product of all ancestor alphas)
    /// - It is not hidden (and no ancestor is hidden)
    /// - Its own isUserInteractionEnabled is true
    open func nodes(at p: CGPoint) -> [SKNode] {
        // Stack includes accumulated alpha (visibility propagates through ancestors)
        var stack: [(node: SKNode, point: CGPoint, accZ: CGFloat, depth: Int, accAlpha: CGFloat)] = [
            (self, p, 0, 0, 1.0)  // Start with neutral accumulated alpha
        ]
        var results: [(node: SKNode, z: CGFloat, depth: Int)] = []
        var depthCounter = 0

        while !stack.isEmpty {
            let (node, point, accZ, _, parentAlpha) = stack.removeLast()

            // Skip hidden nodes and their entire subtree
            if node.isHidden { continue }

            // Calculate effective properties for this node
            let effectiveAlpha = parentAlpha * node.alpha

            // Skip if effectively invisible
            if effectiveAlpha == 0 { continue }

            let currentDepth = depthCounter
            depthCounter += 1
            let nodeZ = accZ + node.zPosition

            // Add to results only if hittable (visible AND interactive AND at point)
            if node.isUserInteractionEnabled && node._contentBounds.contains(point) {
                results.append((node, nodeZ, currentDepth))
            }

            // Add children with accumulated properties
            for child in node.children.reversed() {
                let childPoint = node.convertPointToChild(point, child: child)
                stack.append((child, childPoint, nodeZ, 0, effectiveAlpha))
            }
        }

        // Sort by zPosition (descending), then by depth (descending)
        results.sort { a, b in
            if a.z != b.z {
                return a.z > b.z
            }
            return a.depth > b.depth
        }

        return results.map { $0.node }
    }

    /// Returns a Boolean value that indicates whether this node intersects the specified node.
    ///
    /// - Parameter node: The node to test for intersection.
    /// - Returns: `true` if the nodes' frames intersect.
    open func intersects(_ node: SKNode) -> Bool {
        // Convert both bounds to a common coordinate system
        guard let commonAncestor = findCommonAncestor(with: node) else {
            return false
        }

        // Use bounds (local coords) and transform through the node chain
        let selfBoundsInCommon = convertBoundsToAncestor(ancestor: commonAncestor)
        let nodeBoundsInCommon = node.convertBoundsToAncestor(ancestor: commonAncestor)

        return selfBoundsInCommon.intersects(nodeBoundsInCommon)
    }

    private func findCommonAncestor(with other: SKNode) -> SKNode? {
        var ancestors = Set<ObjectIdentifier>()
        var current: SKNode? = self
        while let node = current {
            ancestors.insert(ObjectIdentifier(node))
            current = node.parent
        }

        current = other
        while let node = current {
            if ancestors.contains(ObjectIdentifier(node)) {
                return node
            }
            current = node.parent
        }

        return nil
    }

    /// Converts this node's bounds to the coordinate system of an ancestor node.
    ///
    /// Starts with `bounds` (local coordinates) and applies each node's transform
    /// going up the parent chain to the specified ancestor.
    ///
    /// - Parameter ancestor: The ancestor node whose coordinate system to convert to.
    /// - Returns: The bounds rectangle in the ancestor's coordinate system.
    private func convertBoundsToAncestor(ancestor: SKNode) -> CGRect {
        var result = _contentBounds  // Start with local coords
        var current: SKNode? = self

        // Transform through each node up to (but not including) the ancestor
        while let node = current, node !== ancestor {
            result = node.transformRectToParent(result)
            current = node.parent
        }

        return result
    }

    /// Transforms a rectangle from this node's local coordinate system to the parent's coordinate system.
    ///
    /// This applies the node's position, scale, and rotation to the rectangle.
    /// If the node has rotation, the result is an axis-aligned bounding box (AABB) of the rotated rectangle.
    private func transformRectToParent(_ rect: CGRect) -> CGRect {
        // Transform all 4 corners and compute AABB
        // This handles rotation and negative scale correctly
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY)
        ]

        let cosA = cos(zRotation)
        let sinA = sin(zRotation)

        var minX = CGFloat.infinity
        var minY = CGFloat.infinity
        var maxX = -CGFloat.infinity
        var maxY = -CGFloat.infinity

        for corner in corners {
            let scaled = CGPoint(x: corner.x * xScale, y: corner.y * yScale)
            let rotated = CGPoint(
                x: scaled.x * cosA - scaled.y * sinA + position.x,
                y: scaled.x * sinA + scaled.y * cosA + position.y
            )
            minX = min(minX, rotated.x)
            minY = min(minY, rotated.y)
            maxX = max(maxX, rotated.x)
            maxY = max(maxY, rotated.y)
        }

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    // MARK: - Coordinate Conversion

    /// Converts a point from the coordinate system of another node in the node tree
    /// to the coordinate system of this node.
    ///
    /// - Parameters:
    ///   - point: A point in the other node's coordinate system.
    ///   - node: The node whose coordinate system the point is in.
    /// - Returns: The point converted to this node's coordinate system.
    open func convert(_ point: CGPoint, from node: SKNode) -> CGPoint {
        // Early exit for same node
        if node === self {
            return point
        }

        // Convert point from source node to scene coordinates
        let scenePoint = node.convertToScene(point)

        // Convert from scene coordinates to this node's coordinate system
        return convertFromScene(scenePoint)
    }

    /// Converts a point in this node's coordinate system to the coordinate system
    /// of another node in the node tree.
    ///
    /// - Parameters:
    ///   - point: A point in this node's coordinate system.
    ///   - node: The target node whose coordinate system to convert to.
    /// - Returns: The point converted to the target node's coordinate system.
    open func convert(_ point: CGPoint, to node: SKNode) -> CGPoint {
        // Early exit for same node
        if node === self {
            return point
        }

        // Convert point from this node to scene coordinates
        let scenePoint = convertToScene(point)

        // Convert from scene coordinates to target node
        return node.convertFromScene(scenePoint)
    }

    // MARK: - Internal Coordinate Conversion Helpers

    /// Converts a point from this node's local coordinate system to scene coordinates.
    /// Applies scale, rotation, and position transforms up the hierarchy.
    private func convertToScene(_ point: CGPoint) -> CGPoint {
        var result = point
        var current: SKNode? = self

        while let n = current, !(n is SKScene) {
            // Apply scale
            result.x *= n.xScale
            result.y *= n.yScale

            // Apply rotation
            if n.zRotation != 0 {
                let cosAngle = cos(n.zRotation)
                let sinAngle = sin(n.zRotation)
                let rotatedX = result.x * cosAngle - result.y * sinAngle
                let rotatedY = result.x * sinAngle + result.y * cosAngle
                result.x = rotatedX
                result.y = rotatedY
            }

            // Apply position (translate to parent's coordinate system)
            result.x += n.position.x
            result.y += n.position.y

            current = n.parent
        }

        return result
    }

    /// Converts a point from scene coordinates to this node's local coordinate system.
    /// Applies inverse transforms (position, rotation, scale) down the hierarchy.
    private func convertFromScene(_ point: CGPoint) -> CGPoint {
        // Build the path from scene to this node
        var path: [SKNode] = []
        var current: SKNode? = self
        while let n = current, !(n is SKScene) {
            path.append(n)
            current = n.parent
        }

        // Apply inverse transforms from scene down to this node
        var result = point
        for n in path.reversed() {
            // Inverse position (translate from parent's coordinate system)
            result.x -= n.position.x
            result.y -= n.position.y

            // Inverse rotation
            if n.zRotation != 0 {
                let cosAngle = cos(-n.zRotation)
                let sinAngle = sin(-n.zRotation)
                let rotatedX = result.x * cosAngle - result.y * sinAngle
                let rotatedY = result.x * sinAngle + result.y * cosAngle
                result.x = rotatedX
                result.y = rotatedY
            }

            // Inverse scale
            if n.xScale != 0 {
                result.x /= n.xScale
            }
            if n.yScale != 0 {
                result.y /= n.yScale
            }
        }

        return result
    }
}

// MARK: - Equatable

extension SKNode: Equatable {
    public static func == (lhs: SKNode, rhs: SKNode) -> Bool {
        return lhs === rhs
    }
}

// MARK: - Hashable

extension SKNode: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
