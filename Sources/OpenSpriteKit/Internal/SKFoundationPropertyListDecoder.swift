import OpenFoundation

internal struct SKFoundationPropertyListDecoder: SKPropertyListDecoding {
    internal init() {}

    internal func propertyList(from data: Data) throws -> Any {
        try PropertyListSerialization.propertyList(from: data, format: nil)
    }
}
