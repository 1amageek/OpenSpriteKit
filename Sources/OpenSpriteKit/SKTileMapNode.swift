// SKTileMapNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation

// MARK: - SKTileSetType

/// An enumeration defining how tiles are arranged.
public enum SKTileSetType: UInt, Sendable, Hashable {
    /// A grid of rectangular tiles.
    case grid = 0

    /// A grid of hexagonal tiles with flat tops.
    case hexagonalFlat = 1

    /// A grid of hexagonal tiles with pointy tops.
    case hexagonalPointy = 2

    /// An isometric (diamond) grid of tiles.
    case isometric = 3
}

// MARK: - SKTileAdjacencyMask

/// A structure defining how neighboring tiles are automatically placed.
public struct SKTileAdjacencyMask: OptionSet, Sendable, Hashable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    // MARK: - Cardinal Directions

    public static let adjacencyUp = SKTileAdjacencyMask(rawValue: 1 << 0)
    public static let adjacencyUpperRight = SKTileAdjacencyMask(rawValue: 1 << 1)
    public static let adjacencyRight = SKTileAdjacencyMask(rawValue: 1 << 2)
    public static let adjacencyLowerRight = SKTileAdjacencyMask(rawValue: 1 << 3)
    public static let adjacencyDown = SKTileAdjacencyMask(rawValue: 1 << 4)
    public static let adjacencyLowerLeft = SKTileAdjacencyMask(rawValue: 1 << 5)
    public static let adjacencyLeft = SKTileAdjacencyMask(rawValue: 1 << 6)
    public static let adjacencyUpperLeft = SKTileAdjacencyMask(rawValue: 1 << 7)

    // MARK: - Edges

    public static let adjacencyUpEdge = SKTileAdjacencyMask(rawValue: 1 << 8)
    public static let adjacencyUpperRightEdge = SKTileAdjacencyMask(rawValue: 1 << 9)
    public static let adjacencyRightEdge = SKTileAdjacencyMask(rawValue: 1 << 10)
    public static let adjacencyLowerRightEdge = SKTileAdjacencyMask(rawValue: 1 << 11)
    public static let adjacencyDownEdge = SKTileAdjacencyMask(rawValue: 1 << 12)
    public static let adjacencyLowerLeftEdge = SKTileAdjacencyMask(rawValue: 1 << 13)
    public static let adjacencyLeftEdge = SKTileAdjacencyMask(rawValue: 1 << 14)
    public static let adjacencyUpperLeftEdge = SKTileAdjacencyMask(rawValue: 1 << 15)

    // MARK: - Corners

    public static let adjacencyUpperRightCorner = SKTileAdjacencyMask(rawValue: 1 << 16)
    public static let adjacencyLowerRightCorner = SKTileAdjacencyMask(rawValue: 1 << 17)
    public static let adjacencyLowerLeftCorner = SKTileAdjacencyMask(rawValue: 1 << 18)
    public static let adjacencyUpperLeftCorner = SKTileAdjacencyMask(rawValue: 1 << 19)

    // MARK: - All

    public static let adjacencyAll: SKTileAdjacencyMask = [
        .adjacencyUp, .adjacencyUpperRight, .adjacencyRight, .adjacencyLowerRight,
        .adjacencyDown, .adjacencyLowerLeft, .adjacencyLeft, .adjacencyUpperLeft
    ]

    // MARK: - Hexagonal Flat

    public static let hexFlatAdjacencyUp = SKTileAdjacencyMask(rawValue: 1 << 20)
    public static let hexFlatAdjacencyUpperRight = SKTileAdjacencyMask(rawValue: 1 << 21)
    public static let hexFlatAdjacencyLowerRight = SKTileAdjacencyMask(rawValue: 1 << 22)
    public static let hexFlatAdjacencyDown = SKTileAdjacencyMask(rawValue: 1 << 23)
    public static let hexFlatAdjacencyLowerLeft = SKTileAdjacencyMask(rawValue: 1 << 24)
    public static let hexFlatAdjacencyUpperLeft = SKTileAdjacencyMask(rawValue: 1 << 25)

    public static let hexFlatAdjacencyAll: SKTileAdjacencyMask = [
        .hexFlatAdjacencyUp, .hexFlatAdjacencyUpperRight, .hexFlatAdjacencyLowerRight,
        .hexFlatAdjacencyDown, .hexFlatAdjacencyLowerLeft, .hexFlatAdjacencyUpperLeft
    ]

    // MARK: - Hexagonal Pointy

    public static let hexPointyAdjacencyUpperLeft = SKTileAdjacencyMask(rawValue: 1 << 26)
    public static let hexPointyAdjacencyUpperRight = SKTileAdjacencyMask(rawValue: 1 << 27)
    public static let hexPointyAdjacencyRight = SKTileAdjacencyMask(rawValue: 1 << 28)
    public static let hexPointyAdjacencyLowerRight = SKTileAdjacencyMask(rawValue: 1 << 29)
    public static let hexPointyAdjacencyLowerLeft = SKTileAdjacencyMask(rawValue: 1 << 30)
    public static let hexPointyAdjacencyLeft = SKTileAdjacencyMask(rawValue: 1 << 31)

    public static let hexPointyAdjacencyAdd: SKTileAdjacencyMask = [
        .hexPointyAdjacencyUpperLeft, .hexPointyAdjacencyUpperRight, .hexPointyAdjacencyRight,
        .hexPointyAdjacencyLowerRight, .hexPointyAdjacencyLowerLeft, .hexPointyAdjacencyLeft
    ]
}

// MARK: - SKTileDefinition

/// A single tile that can be placed in a tile map.
open class SKTileDefinition: @unchecked Sendable {

    /// The textures used for this tile.
    open var textures: [SKTexture] = []

    /// The normal textures for this tile.
    open var normalTextures: [SKTexture] = []

    /// The size of the tile in points.
    open var size: CGSize = CGSize(width: 32, height: 32)

    /// The time per frame for animated tiles.
    open var timePerFrame: CGFloat = 0.1

    /// The placement weight for this tile.
    open var placementWeight: Int = 1

    /// A name for this tile definition.
    open var name: String?

    /// User data for this tile.
    open var userData: [String: Any]?

    /// The rotation of this tile.
    open var rotation: SKTileDefinitionRotation = .rotation0

    /// Whether this tile should flip vertically.
    open var flipVertically: Bool = false

    /// Whether this tile should flip horizontally.
    open var flipHorizontally: Bool = false

    public init() {
    }

    public init(texture: SKTexture) {
        self.textures = [texture]
        self.size = texture.size()
    }

    public init(texture: SKTexture, size: CGSize) {
        self.textures = [texture]
        self.size = size
    }

    public init(texture: SKTexture, normalTexture: SKTexture, size: CGSize) {
        self.textures = [texture]
        self.normalTextures = [normalTexture]
        self.size = size
    }

    public init(textures: [SKTexture], size: CGSize, timePerFrame: CGFloat) {
        self.textures = textures
        self.size = size
        self.timePerFrame = timePerFrame
    }

    public init(textures: [SKTexture], normalTextures: [SKTexture], size: CGSize, timePerFrame: CGFloat) {
        self.textures = textures
        self.normalTextures = normalTextures
        self.size = size
        self.timePerFrame = timePerFrame
    }

    /// Creates a copy of this tile definition.
    ///
    /// - Returns: A new tile definition with the same properties.
    open func copy() -> SKTileDefinition {
        let definitionCopy = SKTileDefinition()
        definitionCopy.textures = textures
        definitionCopy.normalTextures = normalTextures
        definitionCopy.size = size
        definitionCopy.timePerFrame = timePerFrame
        definitionCopy.placementWeight = placementWeight
        definitionCopy.name = name
        definitionCopy.rotation = rotation
        definitionCopy.flipVertically = flipVertically
        definitionCopy.flipHorizontally = flipHorizontally
        return definitionCopy
    }
}

/// The rotation of a tile definition.
public enum SKTileDefinitionRotation: UInt, Sendable, Hashable {
    case rotation0 = 0
    case rotation90 = 1
    case rotation180 = 2
    case rotation270 = 3
}

// MARK: - SKTileGroupRule

/// A rule that describes how tiles should be placed in a tile map.
open class SKTileGroupRule: @unchecked Sendable {

    /// The adjacency mask for this rule.
    open var adjacency: SKTileAdjacencyMask = []

    /// The tile definitions for this rule.
    open var tileDefinitions: [SKTileDefinition] = []

    /// A name for this rule.
    open var name: String?

    public init() {
    }

    public init(adjacency: SKTileAdjacencyMask, tileDefinitions: [SKTileDefinition]) {
        self.adjacency = adjacency
        self.tileDefinitions = tileDefinitions
    }

    /// Creates a copy of this tile group rule.
    ///
    /// - Returns: A new tile group rule with the same properties.
    open func copy() -> SKTileGroupRule {
        let ruleCopy = SKTileGroupRule()
        ruleCopy.adjacency = adjacency
        ruleCopy.tileDefinitions = tileDefinitions.map { $0.copy() }
        ruleCopy.name = name
        return ruleCopy
    }
}

// MARK: - SKTileGroup

/// A set of related tile definitions and rules.
open class SKTileGroup: @unchecked Sendable {

    /// The rules for this tile group.
    open var rules: [SKTileGroupRule] = []

    /// A name for this tile group.
    open var name: String?

    public init() {
    }

    public init(rules: [SKTileGroupRule]) {
        self.rules = rules
    }

    public init(tileDefinition: SKTileDefinition) {
        let rule = SKTileGroupRule(adjacency: [], tileDefinitions: [tileDefinition])
        self.rules = [rule]
    }

    public class func empty() -> SKTileGroup {
        return SKTileGroup()
    }

    /// Creates a copy of this tile group.
    ///
    /// - Returns: A new tile group with the same properties.
    open func copy() -> SKTileGroup {
        let groupCopy = SKTileGroup()
        groupCopy.rules = rules.map { $0.copy() }
        groupCopy.name = name
        return groupCopy
    }
}

// MARK: - SKTileSet

/// A container for tile groups that define a theme.
open class SKTileSet: @unchecked Sendable {

    /// The type of this tile set.
    open var type: SKTileSetType = .grid

    /// The tile groups in this tile set.
    open var tileGroups: [SKTileGroup] = []

    /// The default tile group for this tile set.
    open var defaultTileGroup: SKTileGroup?

    /// The default tile size for this tile set.
    open var defaultTileSize: CGSize = CGSize(width: 32, height: 32)

    /// A name for this tile set.
    open var name: String?

    public init() {
    }

    public init(tileGroups: [SKTileGroup]) {
        self.tileGroups = tileGroups
    }

    public init(tileGroups: [SKTileGroup], tileSetType: SKTileSetType) {
        self.tileGroups = tileGroups
        self.type = tileSetType
    }

    /// Initializes a tile set by searching the app bundle for an archived .sks file by name.
    ///
    /// On WASM platforms, you must first register the tile set data with `SKResourceLoader`:
    /// ```swift
    /// SKResourceLoader.shared.registerTileSet(data: tileSetData, forName: "MyTileSet")
    /// let tileSet = SKTileSet(named: "MyTileSet")
    /// ```
    ///
    /// - Parameter name: The name of the tile set file (with or without `.sks` extension).
    public convenience init?(named name: String) {
        // Try to load from registered tile set data (WASM)
        if let data = SKResourceLoader.shared.tileSetData(forName: name) {
            guard let parsed = Self.parseTileSet(from: data) else {
                return nil
            }
            self.init(tileGroups: parsed.tileGroups, tileSetType: parsed.type)
            self.name = parsed.name
            self.defaultTileSize = parsed.defaultTileSize
            self.defaultTileGroup = parsed.defaultTileGroup
            return
        }

        // Try to load from bundle (native platforms)
        let nameWithoutExtension = name.hasSuffix(".sks") ? String(name.dropLast(4)) : name

        if let url = Bundle.main.url(forResource: nameWithoutExtension, withExtension: "sks"),
           let data = try? Data(contentsOf: url),
           let parsed = Self.parseTileSet(from: data) {
            self.init(tileGroups: parsed.tileGroups, tileSetType: parsed.type)
            self.name = parsed.name
            self.defaultTileSize = parsed.defaultTileSize
            self.defaultTileGroup = parsed.defaultTileGroup
            return
        }

        return nil
    }

    /// Initializes a tile set from a URL to an archived .sks file.
    ///
    /// - Parameter url: The URL to the tile set file.
    public convenience init?(from url: URL) {
        guard let data = try? Data(contentsOf: url),
              let parsed = Self.parseTileSet(from: data) else {
            return nil
        }
        self.init(tileGroups: parsed.tileGroups, tileSetType: parsed.type)
        self.name = parsed.name
        self.defaultTileSize = parsed.defaultTileSize
        self.defaultTileGroup = parsed.defaultTileGroup
    }

    /// Parses tile set data (property list format).
    private class func parseTileSet(from data: Data) -> SKTileSet? {
        // Parse as property list
        guard let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return nil
        }

        let tileSet = SKTileSet()

        // Parse basic properties
        if let name = plist["name"] as? String {
            tileSet.name = name
        }

        if let typeRaw = plist["type"] as? UInt, let type = SKTileSetType(rawValue: typeRaw) {
            tileSet.type = type
        }

        if let sizeDict = plist["defaultTileSize"] as? [String: Any],
           let width = sizeDict["width"] as? CGFloat,
           let height = sizeDict["height"] as? CGFloat {
            tileSet.defaultTileSize = CGSize(width: width, height: height)
        }

        // Parse tile groups
        if let groupsArray = plist["tileGroups"] as? [[String: Any]] {
            tileSet.tileGroups = groupsArray.compactMap { parseTileGroup(from: $0) }
        }

        return tileSet
    }

    /// Parses a tile group from a dictionary.
    private class func parseTileGroup(from dict: [String: Any]) -> SKTileGroup? {
        let group = SKTileGroup()

        if let name = dict["name"] as? String {
            group.name = name
        }

        if let rulesArray = dict["rules"] as? [[String: Any]] {
            group.rules = rulesArray.compactMap { parseTileGroupRule(from: $0) }
        }

        return group
    }

    /// Parses a tile group rule from a dictionary.
    private class func parseTileGroupRule(from dict: [String: Any]) -> SKTileGroupRule? {
        let rule = SKTileGroupRule()

        if let name = dict["name"] as? String {
            rule.name = name
        }

        if let adjacencyRaw = dict["adjacency"] as? UInt {
            rule.adjacency = SKTileAdjacencyMask(rawValue: adjacencyRaw)
        }

        if let defsArray = dict["tileDefinitions"] as? [[String: Any]] {
            rule.tileDefinitions = defsArray.compactMap { parseTileDefinition(from: $0) }
        }

        return rule
    }

    /// Parses a tile definition from a dictionary.
    private class func parseTileDefinition(from dict: [String: Any]) -> SKTileDefinition? {
        let def = SKTileDefinition()

        if let name = dict["name"] as? String {
            def.name = name
        }

        if let sizeDict = dict["size"] as? [String: Any],
           let width = sizeDict["width"] as? CGFloat,
           let height = sizeDict["height"] as? CGFloat {
            def.size = CGSize(width: width, height: height)
        }

        if let timePerFrame = dict["timePerFrame"] as? CGFloat {
            def.timePerFrame = timePerFrame
        }

        if let placementWeight = dict["placementWeight"] as? Int {
            def.placementWeight = placementWeight
        }

        if let rotationRaw = dict["rotation"] as? UInt, let rotation = SKTileDefinitionRotation(rawValue: rotationRaw) {
            def.rotation = rotation
        }

        if let flipV = dict["flipVertically"] as? Bool {
            def.flipVertically = flipV
        }

        if let flipH = dict["flipHorizontally"] as? Bool {
            def.flipHorizontally = flipH
        }

        // Parse textures (texture names that need to be loaded)
        if let textureNames = dict["textures"] as? [String] {
            def.textures = textureNames.compactMap { name in
                if let image = SKResourceLoader.shared.image(forName: name) {
                    return SKTexture(cgImage: image)
                }
                return nil
            }
        }

        return def
    }

    /// Creates a copy of this tile set.
    ///
    /// - Returns: A new tile set with the same properties.
    open func copy() -> SKTileSet {
        let setCopy = SKTileSet()
        setCopy.type = type
        setCopy.tileGroups = tileGroups.map { $0.copy() }
        setCopy.defaultTileGroup = defaultTileGroup?.copy()
        setCopy.defaultTileSize = defaultTileSize
        setCopy.name = name
        return setCopy
    }
}

// MARK: - SKTileMapNode

/// A node that renders a two-dimensional grid of tiles.
open class SKTileMapNode: SKNode, @unchecked Sendable {

    // MARK: - Properties

    /// The tile set used by this tile map.
    open var tileSet: SKTileSet

    /// The number of columns in the tile map.
    open private(set) var numberOfColumns: Int

    /// The number of rows in the tile map.
    open private(set) var numberOfRows: Int

    /// The size of each tile in points.
    open var tileSize: CGSize {
        didSet {
            _cachedMapSize = nil
        }
    }

    /// The anchor point for the tile map.
    open var anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)

    /// The color to blend with the tile map.
    open var color: SKColor = .white

    /// The blend factor for the color.
    open var colorBlendFactor: CGFloat = 0.0

    /// The blend mode for rendering.
    open var blendMode: SKBlendMode = .alpha

    /// A shader for custom rendering.
    open var shader: SKShader?

    /// The attribute values for the shader.
    open var attributeValues: [String: SKAttributeValue] = [:]

    /// The lighting bit mask.
    open var lightingBitMask: UInt32 = 0

    /// Whether automapping is enabled.
    open var enableAutomapping: Bool = false

    // MARK: - Internal Storage

    /// Flat 1D array for better cache locality and memory efficiency
    private var tiles: [SKTileGroup?]

    /// Cached map size to avoid repeated calculation
    private var _cachedMapSize: CGSize?

    /// Sprite nodes used to render tiles
    private var tileSprites: [SKSpriteNode?] = []

    /// Flag to track if tile sprites need updating
    private var _needsTileUpdate: Bool = true

    /// Animation time accumulator for animated tiles
    private var _animationTime: TimeInterval = 0

    // MARK: - Computed Properties

    /// The size of the tile map in points.
    open var mapSize: CGSize {
        if let cached = _cachedMapSize {
            return cached
        }
        let size = CGSize(
            width: CGFloat(numberOfColumns) * tileSize.width,
            height: CGFloat(numberOfRows) * tileSize.height
        )
        _cachedMapSize = size
        return size
    }

    // MARK: - Private Helpers

    /// Converts 2D coordinates to flat array index
    @inline(__always)
    private func tileIndex(column: Int, row: Int) -> Int {
        return row * numberOfColumns + column
    }

    /// Checks if coordinates are within bounds
    @inline(__always)
    private func isValidCoordinate(column: Int, row: Int) -> Bool {
        return column >= 0 && column < numberOfColumns && row >= 0 && row < numberOfRows
    }

    // MARK: - Initializers

    public init(tileSet: SKTileSet, columns: Int, rows: Int, tileSize: CGSize) {
        self.tileSet = tileSet
        self.numberOfColumns = columns
        self.numberOfRows = rows
        self.tileSize = tileSize
        self.tiles = [SKTileGroup?](repeating: nil, count: columns * rows)
        super.init()
        initializeTileSprites()
    }

    public init(tileSet: SKTileSet, columns: Int, rows: Int, tileSize: CGSize, fillWith tileGroup: SKTileGroup?) {
        self.tileSet = tileSet
        self.numberOfColumns = columns
        self.numberOfRows = rows
        self.tileSize = tileSize
        self.tiles = [SKTileGroup?](repeating: tileGroup, count: columns * rows)
        super.init()
        initializeTileSprites()
    }

    public init(tileSet: SKTileSet, columns: Int, rows: Int, tileSize: CGSize, tileGroupLayout: [SKTileGroup?]) {
        self.tileSet = tileSet
        self.numberOfColumns = columns
        self.numberOfRows = rows
        self.tileSize = tileSize

        let totalTiles = columns * rows
        if tileGroupLayout.count >= totalTiles {
            // Direct slice if input has enough elements
            self.tiles = Array(tileGroupLayout.prefix(totalTiles))
        } else {
            // Pad with nil if input is smaller
            var tiles = tileGroupLayout
            tiles.append(contentsOf: [SKTileGroup?](repeating: nil, count: totalTiles - tileGroupLayout.count))
            self.tiles = tiles
        }
        super.init()
        initializeTileSprites()
    }

    // MARK: - Tile Access

    /// Returns the tile group at the specified column and row.
    open func tileGroup(atColumn column: Int, row: Int) -> SKTileGroup? {
        guard isValidCoordinate(column: column, row: row) else {
            return nil
        }
        return tiles[tileIndex(column: column, row: row)]
    }

    /// Sets the tile group at the specified column and row.
    open func setTileGroup(_ tileGroup: SKTileGroup?, forColumn column: Int, row: Int) {
        guard isValidCoordinate(column: column, row: row) else {
            return
        }
        let index = tileIndex(column: column, row: row)
        tiles[index] = tileGroup
        updateTileSprite(at: index, column: column, row: row)
    }

    /// Sets the tile group using automapping at the specified position.
    open func setTileGroup(_ tileGroup: SKTileGroup?, andTileDefinition tileDefinition: SKTileDefinition, forColumn column: Int, row: Int) {
        guard isValidCoordinate(column: column, row: row) else {
            return
        }
        let index = tileIndex(column: column, row: row)
        tiles[index] = tileGroup
        updateTileSprite(at: index, column: column, row: row, definition: tileDefinition)
    }

    /// Returns the tile definition at the specified column and row.
    open func tileDefinition(atColumn column: Int, row: Int) -> SKTileDefinition? {
        guard let group = tileGroup(atColumn: column, row: row),
              let rule = group.rules.first,
              let definition = rule.tileDefinitions.first else {
            return nil
        }
        return definition
    }

    // MARK: - Coordinate Conversion

    /// Returns the column for the specified position.
    open func tileColumnIndex(fromPosition position: CGPoint) -> Int {
        let mapWidth = mapSize.width
        let adjustedX = position.x + mapWidth * anchorPoint.x
        return Int(adjustedX / tileSize.width)
    }

    /// Returns the row for the specified position.
    open func tileRowIndex(fromPosition position: CGPoint) -> Int {
        let mapHeight = mapSize.height
        let adjustedY = position.y + mapHeight * anchorPoint.y
        return Int(adjustedY / tileSize.height)
    }

    /// Returns the center position of the tile at the specified column and row.
    open func centerOfTile(atColumn column: Int, row: Int) -> CGPoint {
        let size = mapSize
        let halfTileWidth = tileSize.width * 0.5
        let halfTileHeight = tileSize.height * 0.5
        let x = CGFloat(column) * tileSize.width + halfTileWidth - size.width * anchorPoint.x
        let y = CGFloat(row) * tileSize.height + halfTileHeight - size.height * anchorPoint.y
        return CGPoint(x: x, y: y)
    }

    // MARK: - Fill

    /// Fills the entire tile map with the specified tile group.
    open func fill(with tileGroup: SKTileGroup?) {
        // Use withUnsafeMutableBufferPointer for optimal performance
        tiles.withUnsafeMutableBufferPointer { buffer in
            for i in buffer.indices {
                buffer[i] = tileGroup
            }
        }
        rebuildAllTileSprites()
    }

    // MARK: - Shader Attributes

    /// Sets a shader attribute value.
    open func setValue(_ value: SKAttributeValue, forAttribute key: String) {
        attributeValues[key] = value
    }

    /// Gets a shader attribute value.
    open func value(forAttributeNamed name: String) -> SKAttributeValue? {
        return attributeValues[name]
    }

    // MARK: - Tile Sprite Management

    /// Initializes the tile sprites array and creates initial sprites.
    private func initializeTileSprites() {
        let totalTiles = numberOfColumns * numberOfRows
        tileSprites = [SKSpriteNode?](repeating: nil, count: totalTiles)
        rebuildAllTileSprites()
    }

    /// Rebuilds all tile sprites from scratch.
    private func rebuildAllTileSprites() {
        // Remove all existing tile sprites
        for sprite in tileSprites {
            sprite?.removeFromParent()
        }

        let totalTiles = numberOfColumns * numberOfRows
        tileSprites = [SKSpriteNode?](repeating: nil, count: totalTiles)

        // Create sprites for all tiles
        for row in 0..<numberOfRows {
            for column in 0..<numberOfColumns {
                let index = tileIndex(column: column, row: row)
                updateTileSprite(at: index, column: column, row: row)
            }
        }
    }

    /// Updates a single tile sprite at the specified index.
    private func updateTileSprite(at index: Int, column: Int, row: Int, definition: SKTileDefinition? = nil) {
        // Get or create the tile definition
        let tileDef: SKTileDefinition?
        if let def = definition {
            tileDef = def
        } else if let group = tiles[index],
                  let rule = group.rules.first,
                  let def = rule.tileDefinitions.first {
            tileDef = def
        } else {
            tileDef = nil
        }

        // Remove existing sprite if tile is now empty
        if tileDef == nil {
            if let existing = tileSprites[index] {
                existing.removeFromParent()
                tileSprites[index] = nil
            }
            return
        }

        guard let def = tileDef else { return }

        // Get or create sprite for this tile
        let sprite: SKSpriteNode
        if let existing = tileSprites[index] {
            sprite = existing
        } else {
            sprite = SKSpriteNode()
            sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            tileSprites[index] = sprite
            addChild(sprite)
        }

        // Update sprite properties
        sprite.size = def.size != .zero ? def.size : tileSize
        sprite.position = centerOfTile(atColumn: column, row: row)

        // Set texture from definition
        if let texture = def.textures.first {
            sprite.texture = texture
        }

        // Apply rotation
        switch def.rotation {
        case .rotation0:
            sprite.zRotation = 0
        case .rotation90:
            sprite.zRotation = .pi / 2
        case .rotation180:
            sprite.zRotation = .pi
        case .rotation270:
            sprite.zRotation = .pi * 3 / 2
        }

        // Apply flipping via scale
        sprite.xScale = def.flipHorizontally ? -1 : 1
        sprite.yScale = def.flipVertically ? -1 : 1

        // Apply color blending
        sprite.color = color
        sprite.colorBlendFactor = colorBlendFactor
        sprite.blendMode = blendMode
    }

    /// Updates animated tiles for the current frame.
    ///
    /// Call this method from the frame cycle to animate tiles with multiple textures.
    internal func updateAnimatedTiles(deltaTime: TimeInterval) {
        _animationTime += deltaTime

        for row in 0..<numberOfRows {
            for column in 0..<numberOfColumns {
                let index = tileIndex(column: column, row: row)
                guard let sprite = tileSprites[index],
                      let group = tiles[index],
                      let rule = group.rules.first,
                      let def = rule.tileDefinitions.first,
                      def.textures.count > 1 else {
                    continue
                }

                // Calculate current frame based on time
                let frameCount = def.textures.count
                let totalDuration = def.timePerFrame * CGFloat(frameCount)
                let cycleTime = _animationTime.truncatingRemainder(dividingBy: Double(totalDuration))
                let frameIndex = Int(cycleTime / Double(def.timePerFrame)) % frameCount

                sprite.texture = def.textures[frameIndex]
            }
        }
    }
}
