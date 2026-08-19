internal protocol SKResourceProviding: Sendable {
    func data(named name: String, allowedExtensions: [String]) throws -> Data
    func data(contentsOf url: URL) throws -> Data
    func url(named name: String, allowedExtensions: [String]) -> URL?
}
