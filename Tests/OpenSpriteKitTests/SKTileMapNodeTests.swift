import Testing
@testable import OpenSpriteKit

// MARK: - SKTileSetType Tests

@Suite("SKTileSetType")
struct SKTileSetTypeTests {

    @Test("Raw values are correct")
    func testRawValues() {
        #expect(SKTileSetType.grid.rawValue == 0)
        #expect(SKTileSetType.hexagonalFlat.rawValue == 1)
        #expect(SKTileSetType.hexagonalPointy.rawValue == 2)
        #expect(SKTileSetType.isometric.rawValue == 3)
    }
}

// MARK: - SKTileAdjacencyMask Tests

@Suite("SKTileAdjacencyMask")
struct SKTileAdjacencyMaskTests {

    @Test("Cardinal directions are distinct")
    func testCardinalDirections() {
        let up = SKTileAdjacencyMask.adjacencyUp
        let down = SKTileAdjacencyMask.adjacencyDown
        let left = SKTileAdjacencyMask.adjacencyLeft
        let right = SKTileAdjacencyMask.adjacencyRight

        #expect(up != down)
        #expect(left != right)
        #expect(up != left)
    }

    @Test("adjacencyAll contains all cardinal and diagonal")
    func testAdjacencyAll() {
        let all = SKTileAdjacencyMask.adjacencyAll

        #expect(all.contains(.adjacencyUp))
        #expect(all.contains(.adjacencyDown))
        #expect(all.contains(.adjacencyLeft))
        #expect(all.contains(.adjacencyRight))
        #expect(all.contains(.adjacencyUpperLeft))
        #expect(all.contains(.adjacencyUpperRight))
        #expect(all.contains(.adjacencyLowerLeft))
        #expect(all.contains(.adjacencyLowerRight))
    }

    @Test("Can combine masks")
    func testCombineMasks() {
        let combined: SKTileAdjacencyMask = [.adjacencyUp, .adjacencyDown]

        #expect(combined.contains(.adjacencyUp))
        #expect(combined.contains(.adjacencyDown))
        #expect(!combined.contains(.adjacencyLeft))
    }
}

// MARK: - SKTileDefinition Tests

@Suite("SKTileDefinition")
struct SKTileDefinitionTests {

    @Test("Default initialization")
    func testDefaultInit() {
        let definition = SKTileDefinition()

        #expect(definition.textures.isEmpty)
        #expect(definition.size == CGSize(width: 32, height: 32))
        #expect(definition.timePerFrame == 0.1)
        #expect(definition.placementWeight == 1)
        #expect(definition.rotation == .rotation0)
    }

    @Test("Init with texture")
    func testInitWithTexture() {
        let texture = SKTexture(imageNamed: "tile")
        let definition = SKTileDefinition(texture: texture)

        #expect(definition.textures.count == 1)
    }
}

// MARK: - SKTileGroup Tests

@Suite("SKTileGroup")
struct SKTileGroupTests {

    @Test("Empty group")
    func testEmptyGroup() {
        let group = SKTileGroup.empty()

        #expect(group.rules.isEmpty)
    }

    @Test("Init with tile definition")
    func testInitWithTileDefinition() {
        let texture = SKTexture(imageNamed: "tile")
        let definition = SKTileDefinition(texture: texture)
        let group = SKTileGroup(tileDefinition: definition)

        #expect(group.rules.count == 1)
        #expect(group.rules.first?.tileDefinitions.count == 1)
    }
}

// MARK: - SKTileSet Tests

@Suite("SKTileSet")
struct SKTileSetTests {

    @Test("Default initialization")
    func testDefaultInit() {
        let tileSet = SKTileSet()

        #expect(tileSet.type == .grid)
        #expect(tileSet.tileGroups.isEmpty)
        #expect(tileSet.defaultTileSize == CGSize(width: 32, height: 32))
    }

    @Test("Init with type")
    func testInitWithType() {
        let group = SKTileGroup()
        let tileSet = SKTileSet(tileGroups: [group], tileSetType: .hexagonalFlat)

        #expect(tileSet.type == .hexagonalFlat)
        #expect(tileSet.tileGroups.count == 1)
    }
}

// MARK: - SKTileMapNode Tests

@Suite("SKTileMapNode")
struct SKTileMapNodeTests {

    @Test("Initialization")
    func testInit() {
        let tileSet = SKTileSet()
        let tileMap = SKTileMapNode(
            tileSet: tileSet,
            columns: 10,
            rows: 8,
            tileSize: CGSize(width: 32, height: 32)
        )

        #expect(tileMap.numberOfColumns == 10)
        #expect(tileMap.numberOfRows == 8)
        #expect(tileMap.tileSize == CGSize(width: 32, height: 32))
    }

    @Test("Map size calculation")
    func testMapSize() {
        let tileSet = SKTileSet()
        let tileMap = SKTileMapNode(
            tileSet: tileSet,
            columns: 10,
            rows: 5,
            tileSize: CGSize(width: 32, height: 32)
        )

        #expect(tileMap.mapSize == CGSize(width: 320, height: 160))
    }

    @Test("Tile group at position")
    func testTileGroupAtPosition() {
        let tileSet = SKTileSet()
        let group = SKTileGroup()
        let tileMap = SKTileMapNode(
            tileSet: tileSet,
            columns: 5,
            rows: 5,
            tileSize: CGSize(width: 32, height: 32)
        )

        tileMap.setTileGroup(group, forColumn: 2, row: 3)

        #expect(tileMap.tileGroup(atColumn: 2, row: 3) != nil)
        #expect(tileMap.tileGroup(atColumn: 0, row: 0) == nil)
    }

    @Test("Fill with tile group")
    func testFillWithTileGroup() {
        let tileSet = SKTileSet()
        let group = SKTileGroup()
        let tileMap = SKTileMapNode(
            tileSet: tileSet,
            columns: 3,
            rows: 3,
            tileSize: CGSize(width: 32, height: 32)
        )

        tileMap.fill(with: group)

        #expect(tileMap.tileGroup(atColumn: 0, row: 0) != nil)
        #expect(tileMap.tileGroup(atColumn: 2, row: 2) != nil)
    }

    @Test("Center of tile calculation")
    func testCenterOfTile() {
        let tileSet = SKTileSet()
        let tileMap = SKTileMapNode(
            tileSet: tileSet,
            columns: 2,
            rows: 2,
            tileSize: CGSize(width: 32, height: 32)
        )
        tileMap.anchorPoint = CGPoint(x: 0, y: 0)

        let center = tileMap.centerOfTile(atColumn: 0, row: 0)

        #expect(center.x == 16) // Half of tile width
        #expect(center.y == 16) // Half of tile height
    }

    @Test("Out of bounds returns nil")
    func testOutOfBounds() {
        let tileSet = SKTileSet()
        let tileMap = SKTileMapNode(
            tileSet: tileSet,
            columns: 5,
            rows: 5,
            tileSize: CGSize(width: 32, height: 32)
        )

        #expect(tileMap.tileGroup(atColumn: -1, row: 0) == nil)
        #expect(tileMap.tileGroup(atColumn: 5, row: 0) == nil)
        #expect(tileMap.tileGroup(atColumn: 0, row: -1) == nil)
        #expect(tileMap.tileGroup(atColumn: 0, row: 5) == nil)
    }
}

// MARK: - SKWarpGeometryGrid Tests

@Suite("SKWarpGeometryGrid")
struct SKWarpGeometryGridTests {

    @Test("Vertex order is top-to-bottom")
    func testVertexOrder() {
        // Create 2x2 grid (3x3 vertices)
        let sourcePositions: [SIMD2<Float>] = [
            SIMD2(0, 1), SIMD2(0.5, 1), SIMD2(1, 1),
            SIMD2(0, 0.5), SIMD2(0.5, 0.5), SIMD2(1, 0.5),
            SIMD2(0, 0), SIMD2(0.5, 0), SIMD2(1, 0)
        ]
        let grid = SKWarpGeometryGrid(columns: 2, rows: 2, sourcePositions: sourcePositions, destinationPositions: sourcePositions)

        // First vertex should be top-left (0, 1)
        #expect(grid.sourcePositions[0].x == 0)
        #expect(grid.sourcePositions[0].y == 1)

        // Last vertex should be bottom-right (1, 0)
        let lastIndex = grid.sourcePositions.count - 1
        #expect(grid.sourcePositions[lastIndex].x == 1)
        #expect(grid.sourcePositions[lastIndex].y == 0)
    }

    @Test("Vertex count is correct")
    func testVertexCount() {
        // Create 2x2 grid (3x3 vertices = 9)
        let sourcePositions: [SIMD2<Float>] = [
            SIMD2(0, 1), SIMD2(0.5, 1), SIMD2(1, 1),
            SIMD2(0, 0.5), SIMD2(0.5, 0.5), SIMD2(1, 0.5),
            SIMD2(0, 0), SIMD2(0.5, 0), SIMD2(1, 0)
        ]
        let grid = SKWarpGeometryGrid(columns: 2, rows: 2, sourcePositions: sourcePositions, destinationPositions: sourcePositions)

        // 3 columns of vertices * 3 rows of vertices = 9
        #expect(grid.sourcePositions.count == 9)
        #expect(grid.destinationPositions.count == 9)
    }
}
