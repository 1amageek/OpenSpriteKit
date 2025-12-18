// SKNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

#if canImport(QuartzCore)
import QuartzCore
#else
import OpenCoreAnimation
#endif

/// The base class of all SpriteKit nodes.
///
/// `SKNode` provides base properties for its subclasses and can be used as a container
/// or layout tool for other nodes. Nodes inherit the properties of their parent.
///
/// `SKNode` does not draw any content itself. Its visual counterparts include
/// `SKSpriteNode`, `SKShapeNode`, `SKLabelNode`, and other drawing nodes.
open class SKNode: NSObject, NSCopying, NSSecureCoding {

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

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
    open var userData: NSMutableDictionary?

    // MARK: - Initializers

    /// Initializes a blank node.
    public override init() {
        super.init()
    }

    /// Creates a new node by loading an archive file from the game's main bundle.
    ///
    /// - Parameter filename: The name of the archive file (without the `.sks` extension).
    /// - Returns: A new node loaded from the archive, or `nil` if the file could not be loaded.
    public convenience init?(fileNamed filename: String) {
        // TODO: Implement archive loading
        self.init()
    }

    /// Creates a new node by loading an archive file with secure coding.
    ///
    /// - Parameters:
    ///   - filename: The name of the archive file (without the `.sks` extension).
    ///   - classes: A set of classes that are allowed to be unarchived.
    /// - Throws: An error if the archive could not be loaded.
    public convenience init(fileNamed filename: String, securelyWithClasses classes: Set<AnyHashable>) throws {
        // TODO: Implement secure archive loading
        self.init()
    }

    /// Called when a node is initialized from an `.sks` file.
    ///
    /// - Parameter coder: The coder to read data from.
    public required init?(coder: NSCoder) {
        super.init()
        // TODO: Implement decoding
    }

    // MARK: - NSCoding

    public func encode(with coder: NSCoder) {
        // TODO: Implement encoding
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SKNode()
        copy.position = position
        copy.zPosition = zPosition
        copy.zRotation = zRotation
        copy.xScale = xScale
        copy.yScale = yScale
        copy.alpha = alpha
        copy.isHidden = isHidden
        copy.speed = speed
        copy.isPaused = isPaused
        copy.name = name
        copy.isUserInteractionEnabled = isUserInteractionEnabled
        copy.focusBehavior = focusBehavior
        copy.userData = userData?.mutableCopy() as? NSMutableDictionary
        return copy
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
        var accumulated = frame
        for child in children {
            let childFrame = child.calculateAccumulatedFrame()
            // Convert child frame to this node's coordinate system
            let convertedFrame = CGRect(
                x: childFrame.origin.x + child.position.x,
                y: childFrame.origin.y + child.position.y,
                width: childFrame.width,
                height: childFrame.height
            )
            accumulated = accumulated.union(convertedFrame)
        }
        return accumulated
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
        // Simple search (non-path based)
        if !name.contains("/") && !name.contains("*") && !name.contains(".") {
            return children.first { $0.name == name }
        }
        // For path-based searches, use the subscript operator
        return self[name].first
    }

    /// Searches the children of the receiving node to perform processing for nodes that share a name.
    ///
    /// - Parameters:
    ///   - name: The name to search for (supports path notation).
    ///   - block: A block to execute for each found node. Set `stop` to `true` to stop enumeration.
    open func enumerateChildNodes(withName name: String, using block: (SKNode, UnsafeMutablePointer<ObjCBool>) -> Void) {
        var stop = ObjCBool(false)

        // Optimize for simple name search (most common case)
        if !name.contains("/") && !name.contains("*") && !name.contains(".") {
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
            enumerateAllDescendants(root: root, pattern: subpattern, stop: &stop, block: block)
            return
        }

        // Handle path-based search
        let components = pattern.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        enumerateWithComponents(components, from: root, stop: &stop, block: block)
    }

    private func enumerateAllDescendants(root: SKNode, pattern: String, stop: inout ObjCBool, block: (SKNode, UnsafeMutablePointer<ObjCBool>) -> Void) {
        if stop.boolValue { return }

        for child in root.children {
            if stop.boolValue { return }

            if pattern == "*" || child.name == pattern {
                block(child, &stop)
                if stop.boolValue { return }
            }
            enumerateAllDescendants(root: child, pattern: pattern, stop: &stop, block: block)
        }
    }

    private func enumerateWithComponents(_ components: [String], from node: SKNode, stop: inout ObjCBool, block: (SKNode, UnsafeMutablePointer<ObjCBool>) -> Void) {
        if stop.boolValue { return }
        guard !components.isEmpty else { return }

        var remaining = components
        let first = remaining.removeFirst()

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
                    if child.name == first {
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
                    if child.name == first {
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
            return searchAllDescendants(root: root, pattern: subpattern)
        }

        // Handle path-based search
        let components = pattern.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        return searchWithComponents(components, from: root)
    }

    private func searchWithComponents(_ components: [String], from node: SKNode) -> [SKNode] {
        guard !components.isEmpty else { return [] }

        var current = components
        let first = current.removeFirst()

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
            matches = node.children.filter { $0.name == first }
        }

        if current.isEmpty {
            return matches
        }

        return matches.flatMap { searchWithComponents(current, from: $0) }
    }

    private func searchAllDescendants(root: SKNode, pattern: String) -> [SKNode] {
        var results: [SKNode] = []

        func search(node: SKNode) {
            if pattern == "*" || node.name == pattern {
                results.append(node)
            }
            for child in node.children {
                search(node: child)
            }
        }

        for child in root.children {
            search(node: child)
        }

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
    /// - Parameter p: A point in the node's coordinate system.
    /// - Returns: `true` if the point is inside the node's frame.
    open func contains(_ p: CGPoint) -> Bool {
        return frame.contains(p)
    }

    /// Returns the deepest visible descendant that intersects a point.
    ///
    /// - Parameter p: A point in the node's coordinate system.
    /// - Returns: The deepest descendant at the point, or this node if no descendants are at the point.
    open func atPoint(_ p: CGPoint) -> SKNode {
        // Search children in reverse order (top-most first)
        for child in children.reversed() {
            if child.isHidden { continue }
            let childPoint = CGPoint(x: p.x - child.position.x, y: p.y - child.position.y)
            if child.contains(childPoint) {
                return child.atPoint(childPoint)
            }
        }
        return self
    }

    /// Returns an array of all visible descendants that intersect a point.
    ///
    /// The array is sorted in reverse drawing order (topmost node first).
    ///
    /// - Parameter p: A point in the node's coordinate system.
    /// - Returns: An array of nodes at the specified point, sorted with topmost first.
    open func nodes(at p: CGPoint) -> [SKNode] {
        // Use a stack-based approach instead of recursion with captured variables
        var stack: [(node: SKNode, point: CGPoint, accZ: CGFloat, depth: Int)] = [(self, p, 0, 0)]
        var results: [(node: SKNode, z: CGFloat, depth: Int)] = []
        var depthCounter = 0

        while !stack.isEmpty {
            let (node, point, accZ, _) = stack.removeLast()

            if node.isHidden { continue }

            let currentDepth = depthCounter
            depthCounter += 1
            let nodeZ = accZ + node.zPosition

            if node.contains(point) {
                results.append((node, nodeZ, currentDepth))
            }

            // Add children in reverse order so they're processed in correct order
            for child in node.children.reversed() {
                let childPoint = CGPoint(x: point.x - child.position.x, y: point.y - child.position.y)
                stack.append((child, childPoint, nodeZ, 0))
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
        // Convert both frames to a common coordinate system
        guard let commonAncestor = findCommonAncestor(with: node) else {
            return false
        }

        let selfFrameInCommon = convertFrameToAncestor(frame, ancestor: commonAncestor)
        let nodeFrameInCommon = node.convertFrameToAncestor(node.frame, ancestor: commonAncestor)

        return selfFrameInCommon.intersects(nodeFrameInCommon)
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

    private func convertFrameToAncestor(_ rect: CGRect, ancestor: SKNode) -> CGRect {
        var result = rect
        var current: SKNode? = self
        while let node = current, node !== ancestor {
            result = CGRect(
                x: result.origin.x + node.position.x,
                y: result.origin.y + node.position.y,
                width: result.width,
                height: result.height
            )
            current = node.parent
        }
        return result
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
        var scenePoint = point
        var current: SKNode? = node
        while let n = current, !(n is SKScene) {
            scenePoint.x += n.position.x
            scenePoint.y += n.position.y
            current = n.parent
        }

        // Convert from scene coordinates to this node (no array allocation)
        current = self
        while let n = current, !(n is SKScene) {
            scenePoint.x -= n.position.x
            scenePoint.y -= n.position.y
            current = n.parent
        }

        return scenePoint
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
        var scenePoint = point
        var current: SKNode? = self
        while let n = current, !(n is SKScene) {
            scenePoint.x += n.position.x
            scenePoint.y += n.position.y
            current = n.parent
        }

        // Convert from scene coordinates to target node
        // We need to collect the path to subtract in reverse order
        var targetPath: [SKNode] = []
        current = node
        while let n = current, !(n is SKScene) {
            targetPath.append(n)
            current = n.parent
        }

        // Subtract in reverse order (from scene down to target)
        for n in targetPath.reversed() {
            scenePoint.x -= n.position.x
            scenePoint.y -= n.position.y
        }

        return scenePoint
    }
}
