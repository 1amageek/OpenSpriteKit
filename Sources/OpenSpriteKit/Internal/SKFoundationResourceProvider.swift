import OpenFoundation

internal struct SKFoundationResourceProvider: SKResourceProviding {
    internal init() {}

    internal func data(named name: String, allowedExtensions: [String]) throws -> Data {
        guard let url = url(named: name, allowedExtensions: allowedExtensions) else {
            throw SKResourceError.notFound
        }
        return try Data(contentsOf: url)
    }

    internal func data(contentsOf url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    internal func url(named name: String, allowedExtensions: [String]) -> URL? {
        let nameURL = URL(fileURLWithPath: name)
        if !nameURL.pathExtension.isEmpty {
            return Bundle.main.url(
                forResource: nameURL.deletingPathExtension().lastPathComponent,
                withExtension: nameURL.pathExtension
            )
        }

        for fileExtension in allowedExtensions {
            if let url = Bundle.main.url(forResource: name, withExtension: fileExtension) {
                return url
            }
        }
        return nil
    }
}
