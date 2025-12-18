import Testing
@testable import OpenSpriteKit

// MARK: - SKRange Tests

@Suite("SKRange Initialization")
struct SKRangeInitializationTests {

    @Test("Init with lower and upper limits")
    func testInitWithLimits() {
        let range = SKRange(lowerLimit: 0, upperLimit: 100)

        #expect(range.lowerLimit == 0)
        #expect(range.upperLimit == 100)
    }

    @Test("Init with value and variance")
    func testInitWithValueAndVariance() {
        let range = SKRange(value: 50, variance: 10)

        #expect(range.lowerLimit == 40)
        #expect(range.upperLimit == 60)
    }

    @Test("Init with only lower limit")
    func testInitWithLowerLimit() {
        let range = SKRange(lowerLimit: 10)

        #expect(range.lowerLimit == 10)
        #expect(range.upperLimit == .infinity)
    }

    @Test("Init with only upper limit")
    func testInitWithUpperLimit() {
        let range = SKRange(upperLimit: 90)

        #expect(range.lowerLimit == -.infinity)
        #expect(range.upperLimit == 90)
    }

    @Test("Init with constant value")
    func testInitWithConstantValue() {
        let range = SKRange(constantValue: 42)

        #expect(range.lowerLimit == 42)
        #expect(range.upperLimit == 42)
    }

    @Test("withNoLimits creates infinite range")
    func testWithNoLimits() {
        let range = SKRange.withNoLimits()

        #expect(range.lowerLimit == -.infinity)
        #expect(range.upperLimit == .infinity)
    }
}

// MARK: - SKRange Properties Tests

@Suite("SKRange Properties")
struct SKRangePropertiesTests {

    @Test("Lower limit can be changed")
    func testLowerLimitChange() {
        let range = SKRange(lowerLimit: 0, upperLimit: 100)
        range.lowerLimit = 10

        #expect(range.lowerLimit == 10)
    }

    @Test("Upper limit can be changed")
    func testUpperLimitChange() {
        let range = SKRange(lowerLimit: 0, upperLimit: 100)
        range.upperLimit = 90

        #expect(range.upperLimit == 90)
    }
}

// MARK: - SKRange Copy Tests

@Suite("SKRange Copy")
struct SKRangeCopyTests {

    @Test("Copy creates independent instance")
    func testCopy() {
        let original = SKRange(lowerLimit: 0, upperLimit: 100)
        let copy = original.copy() as! SKRange

        #expect(copy.lowerLimit == original.lowerLimit)
        #expect(copy.upperLimit == original.upperLimit)

        // Modify copy, original should be unchanged
        copy.lowerLimit = 50
        #expect(original.lowerLimit == 0)
    }
}

// MARK: - SKRegion Initialization Tests

@Suite("SKRegion Initialization")
struct SKRegionInitializationTests {

    @Test("Default initialization creates empty region")
    func testDefaultInit() {
        let region = SKRegion()

        #expect(region.path == nil)
    }

    @Test("infinite() creates infinite region")
    func testInfiniteRegion() {
        let region = SKRegion.infinite()

        // Infinite region contains all points
        #expect(region.contains(CGPoint(x: 1000000, y: 1000000)) == true)
        #expect(region.contains(CGPoint(x: -1000000, y: -1000000)) == true)
    }

    @Test("Init with size creates rectangular region")
    func testInitWithSize() {
        let region = SKRegion(size: CGSize(width: 100, height: 50))

        #expect(region.path != nil)
    }

    @Test("Init with radius creates circular region")
    func testInitWithRadius() {
        let region = SKRegion(radius: 50)

        #expect(region.path != nil)
    }

    @Test("Init with path uses provided path")
    func testInitWithPath() {
        let path = CGMutablePath()
        path.addRect(CGRect(x: 0, y: 0, width: 100, height: 100))

        let region = SKRegion(path: path)

        #expect(region.path != nil)
    }
}

// MARK: - SKRegion Contains Tests

@Suite("SKRegion Contains")
struct SKRegionContainsTests {

    @Test("Rectangular region contains center point")
    func testRectangularContainsCenter() {
        let region = SKRegion(size: CGSize(width: 100, height: 100))

        #expect(region.contains(CGPoint(x: 0, y: 0)) == true)
    }

    @Test("Rectangular region contains point inside")
    func testRectangularContainsInside() {
        let region = SKRegion(size: CGSize(width: 100, height: 100))

        #expect(region.contains(CGPoint(x: 25, y: 25)) == true)
        #expect(region.contains(CGPoint(x: -25, y: -25)) == true)
    }

    @Test("Rectangular region does not contain point outside")
    func testRectangularNotContainsOutside() {
        let region = SKRegion(size: CGSize(width: 100, height: 100))

        #expect(region.contains(CGPoint(x: 100, y: 100)) == false)
        #expect(region.contains(CGPoint(x: -100, y: -100)) == false)
    }

    @Test("Circular region contains center")
    func testCircularContainsCenter() {
        let region = SKRegion(radius: 50)

        #expect(region.contains(CGPoint(x: 0, y: 0)) == true)
    }

    @Test("Circular region contains point inside radius")
    func testCircularContainsInside() {
        let region = SKRegion(radius: 50)

        #expect(region.contains(CGPoint(x: 25, y: 0)) == true)
        #expect(region.contains(CGPoint(x: 0, y: 25)) == true)
    }

    @Test("Circular region does not contain point outside radius")
    func testCircularNotContainsOutside() {
        let region = SKRegion(radius: 50)

        #expect(region.contains(CGPoint(x: 100, y: 0)) == false)
        #expect(region.contains(CGPoint(x: 0, y: 100)) == false)
    }

    @Test("Infinite region contains any point")
    func testInfiniteContainsAny() {
        let region = SKRegion.infinite()

        #expect(region.contains(CGPoint(x: 0, y: 0)) == true)
        #expect(region.contains(CGPoint(x: 1000, y: 1000)) == true)
        #expect(region.contains(CGPoint(x: -1000, y: -1000)) == true)
    }
}

// MARK: - SKRegion Operations Tests

@Suite("SKRegion Operations")
struct SKRegionOperationsTests {

    @Test("Inverse reverses containment for infinite region")
    func testInverseInfinite() {
        let region = SKRegion.infinite()
        let inverted = region.inverse()

        // Inverted infinite region contains nothing
        #expect(inverted.contains(CGPoint(x: 0, y: 0)) == false)
    }

    @Test("byUnion combines regions")
    func testByUnion() {
        let region1 = SKRegion(size: CGSize(width: 100, height: 100))
        let region2 = SKRegion(size: CGSize(width: 100, height: 100))

        let union = region1.byUnion(with: region2)

        #expect(union.path != nil)
    }

    @Test("byIntersection returns region")
    func testByIntersection() {
        let region1 = SKRegion(size: CGSize(width: 100, height: 100))
        let region2 = SKRegion(size: CGSize(width: 100, height: 100))

        let intersection = region1.byIntersection(with: region2)

        // Intersection should return a valid region
        #expect(intersection != nil)
    }

    @Test("byDifference returns region")
    func testByDifference() {
        let region1 = SKRegion(size: CGSize(width: 100, height: 100))
        let region2 = SKRegion(size: CGSize(width: 50, height: 50))

        let difference = region1.byDifference(from: region2)

        #expect(difference != nil)
    }
}

// MARK: - SKRegion Copy Tests

@Suite("SKRegion Copy")
struct SKRegionCopyTests {

    @Test("Copy creates independent instance")
    func testCopy() {
        let original = SKRegion(size: CGSize(width: 100, height: 100))
        let copy = original.copy() as! SKRegion

        #expect(copy.path != nil)
        #expect(copy !== original)
    }
}
