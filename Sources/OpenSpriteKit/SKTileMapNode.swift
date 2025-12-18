// SKTileMapNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

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
open class SKTileDefinition: NSObject, NSCopying, NSSecureCoding {

    public static var supportsSecureCoding: Bool { true }

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
    open var userData: NSMutableDictionary?

    /// The rotation of this tile.
    open var rotation: SKTileDefinitionRotation = .rotation0

    /// Whether this tile should flip vertically.
    open var flipVertically: Bool = false

    /// Whether this tile should flip horizontally.
    open var flipHorizontally: Bool = false

    public override init() {
        super.init()
    }

    public init(texture: SKTexture) {
        self.textures = [texture]
        self.size = texture.size
        super.init()
    }

    public init(texture: SKTexture, size: CGSize) {
        self.textures = [texture]
        self.size = size
        super.init()
    }

    public init(texture: SKTexture, normalTexture: SKTexture, size: CGSize) {
        self.textures = [texture]
        self.normalTextures = [normalTexture]
        self.size = size
        super.init()
    }

    public init(textures: [SKTexture], size: CGSize, timePerFrame: CGFloat) {
        self.textures = textures
        self.size = size
        self.timePerFrame = timePerFrame
        super.init()
    }

    public init(textures: [SKTexture], normalTextures: [SKTexture], size: CGSize, timePerFrame: CGFloat) {
        self.textures = textures
        self.normalTextures = normalTextures
        self.size = size
        self.timePerFrame = timePerFrame
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
    }

    public func encode(with coder: NSCoder) {}

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SKTileDefinition()
        copy.textures = textures
        copy.normalTextures = normalTextures
        copy.size = size
        copy.timePerFrame = timePerFrame
        copy.placementWeight = placementWeight
        copy.name = name
        copy.rotation = rotation
        copy.flipVertically = flipVertically
        copy.flipHorizontally = flipHorizontally
        return copy
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
open class SKTileGroupRule: NSObject, NSCopying, NSSecureCoding {

    public static var supportsSecureCoding: Bool { true }

    /// The adjacency mask for this rule.
    open var adjacency: SKTileAdjacencyMask = []

    /// The tile definitions for this rule.
    open var tileDefinitions: [SKTileDefinition] = []

    /// A name for this rule.
    open var name: String?

    public override init() {
        super.init()
    }

    public init(adjacency: SKTileAdjacencyMask, tileDefinitions: [SKTileDefinition]) {
        self.adjacency = adjacency
        self.tileDefinitions = tileDefinitions
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
    }

    public func encode(with coder: NSCoder) {}

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SKTileGroupRule()
        copy.adjacency = adjacency
        copy.tileDefinitions = tileDefinitions.map { $0.copy() as! SKTileDefinition }
        copy.name = name
        return copy
    }
}

// MARK: - SKTileGroup

/// A set of related tile definitions and rules.
open class SKTileGroup: NSObject, NSCopying, NSSecureCoding {

    public static var supportsSecureCoding: Bool { true }

    /// The rules for this tile group.
    open var rules: [SKTileGroupRule] = []

    /// A name for this tile group.
    open var name: String?

    public override init() {
        super.init()
    }

    public init(rules: [SKTileGroupRule]) {
        self.rules = rules
        super.init()
    }

    public init(tileDefinition: SKTileDefinition) {
        let rule = SKTileGroupRule(adjacency: [], tileDefinitions: [tileDefinition])
        self.rules = [rule]
        super.init()
    }

    public class func empty() -> SKTileGroup {
        return SKTileGroup()
    }

    public required init?(coder: NSCoder) {
        super.init()
    }

    public func encode(with coder: NSCoder) {}

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SKTileGroup()
        copy.rules = rules.map { $0.copy() as! SKTileGroupRule }
        copy.name = name
        return copy
    }
}

// MARK: - SKTileSet

/// A container for tile groups that define a theme.
open class SKTileSet: NSObject, NSCopying, NSSecureCoding {

    public static var supportsSecureCoding: Bool { true }

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

    public override init() {
        super.init()
    }

    public init(tileGroups: [SKTileGroup]) {
        self.tileGroups = tileGroups
        super.init()
    }

    public init(tileGroups: [SKTileGroup], tileSetType: SKTileSetType) {
        self.tileGroups = tileGroups
        self.type = tileSetType
        super.init()
    }

    public class func tileSet(named name: String) -> SKTileSet? {
        // TODO: Load from resources
        return nil
    }

    public class func tileSet(from url: URL) -> SKTileSet? {
        // TODO: Load from URL
        return nil
    }

    public required init?(coder: NSCoder) {
        super.init()
    }

    public func encode(with coder: NSCoder) {}

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SKTileSet()
        copy.type = type
        copy.tileGroups = tileGroups.map { $0.copy() as! SKTileGroup }
        copy.defaultTileGroup = defaultTileGroup?.copy() as? SKTileGroup
        copy.defaultTileSize = defaultTileSize
        copy.name = name
        return copy
    }
}

// MARK: - SKTileMapNode

/// A node that renders a two-dimensional grid of tiles.
open class SKTileMapNode: SKNode {

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
    }

    public init(tileSet: SKTileSet, columns: Int, rows: Int, tileSize: CGSize, fillWith tileGroup: SKTileGroup?) {
        self.tileSet = tileSet
        self.numberOfColumns = columns
        self.numberOfRows = rows
        self.tileSize = tileSize
        self.tiles = [SKTileGroup?](repeating: tileGroup, count: columns * rows)
        super.init()
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
    }

    public required init?(coder: NSCoder) {
        self.tileSet = SKTileSet()
        self.numberOfColumns = 0
        self.numberOfRows = 0
        self.tileSize = .zero
        self.tiles = []
        super.init(coder: coder)
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
        tiles[tileIndex(column: column, row: row)] = tileGroup
    }

    /// Sets the tile group using automapping at the specified position.
    open func setTileGroup(_ tileGroup: SKTileGroup?, andTileDefinition tileDefinition: SKTileDefinition, forColumn column: Int, row: Int) {
        guard isValidCoordinate(column: column, row: row) else {
            return
        }
        tiles[tileIndex(column: column, row: row)] = tileGroup
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
}
