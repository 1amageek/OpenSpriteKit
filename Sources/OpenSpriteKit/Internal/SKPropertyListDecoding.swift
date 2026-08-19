internal protocol SKPropertyListDecoding: Sendable {
    func propertyList(from data: Data) throws -> Any
}

internal enum SKPropertyListAccess {
    internal static let decoder: any SKPropertyListDecoding =
        SKFoundationPropertyListDecoder()
}
