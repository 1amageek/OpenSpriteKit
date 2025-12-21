// SKReferenceNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation

/// A node that's defined in an archived `.sks` file.
///
/// `SKReferenceNode` is used within an archived `.sks` file to refer to a node defined in another
/// `.sks` file without duplicating its definition. This way, a change to the referenced node
/// propagates to all the references in other files.
///
/// As an example, you might want to share an enemy ship across two different levels, Scene1.sks
/// and Scene2.sks, in a level-based game. Reference nodes allow you to do that without creating
/// copies of the shared node and its properties.
open class SKReferenceNode: SKNode, @unchecked Sendable {

    // MARK: - Properties

    /// The URL of the referenced archive file.
    private var referenceURL: URL?

    /// The file name of the referenced archive.
    private var referenceFileName: String?

    // MARK: - Initializers

    /// Creates a new reference node.
    public override init() {
        super.init()
    }

    /// Initializes a reference node from a URL.
    ///
    /// - Parameter url: The URL of the archived `.sks` file.
    public init(url: URL?) {
        self.referenceURL = url
        super.init()
        if url != nil {
            resolve()
        }
    }

    /// Creates a reference node from a URL.
    ///
    /// - Parameter url: The URL of the archived `.sks` file.
    public convenience init(url: URL) {
        self.init(url: url as URL?)
    }

    /// Initializes a reference node from a file in the app's main bundle.
    ///
    /// - Parameter filename: The name of the archived `.sks` file in the main bundle.
    public init(fileNamed filename: String?) {
        self.referenceFileName = filename
        super.init()
        if filename != nil {
            resolve()
        }
    }


    // MARK: - Regenerating

    /// Loads the reference node's content and adds it as a new child node.
    ///
    /// Call this method to reload the contents of a reference node from its source archive.
    /// This is useful if the source archive has changed and you want to update the reference
    /// node's contents.
    open func resolve() {
        // Remove existing children before reloading
        removeAllChildren()

        var loadedNode: SKNode?

        if let url = referenceURL {
            // Load from URL
            loadedNode = loadNode(from: url)
        } else if let filename = referenceFileName {
            // Load from bundle
            loadedNode = loadNode(named: filename)
        }

        // Call the callback
        didLoad(loadedNode)

        // Add loaded node as child
        if let node = loadedNode {
            addChild(node)
        }
    }

    // MARK: - Loading Callback

    /// A method called by SpriteKit after the reference node's contents are loaded.
    ///
    /// Override this method in a subclass to perform any additional configuration
    /// after the reference node's contents are loaded. The default implementation
    /// does nothing.
    ///
    /// - Parameter node: The node that was loaded from the archive, or nil if loading failed.
    open func didLoad(_ node: SKNode?) {
        // Subclasses can override this method
    }

    // MARK: - Private Loading Methods

    /// Loads a node from a URL.
    ///
    /// - Parameter url: The URL of the archived file.
    /// - Returns: The loaded node, or nil if loading failed.
    private func loadNode(from url: URL) -> SKNode? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return unarchiveNode(from: data)
    }

    /// Loads a node from the main bundle.
    ///
    /// - Parameter filename: The name of the archived file.
    /// - Returns: The loaded node, or nil if loading failed.
    private func loadNode(named filename: String) -> SKNode? {
        // Try with and without extension
        let nameWithoutExtension = (filename as NSString).deletingPathExtension
        let fileExtension = (filename as NSString).pathExtension

        var url: URL?

        if !fileExtension.isEmpty {
            url = Bundle.main.url(forResource: nameWithoutExtension, withExtension: fileExtension)
        } else {
            // Try .sks extension by default
            url = Bundle.main.url(forResource: filename, withExtension: "sks")
        }

        guard let fileURL = url else {
            return nil
        }

        return loadNode(from: fileURL)
    }

    /// Unarchives a node from data using SKSParser.
    ///
    /// - Parameter data: The archived data.
    /// - Returns: The unarchived node, or nil if unarchiving failed.
    private func unarchiveNode(from data: Data) -> SKNode? {
        // Use SKSParser for pure Swift parsing
        do {
            let scene = try SKSParser.parseScene(from: data)
            // Return the scene's first child if it exists, otherwise the scene
            if scene.children.count == 1 {
                return scene.children.first
            }
            return scene
        } catch {
            return nil
        }
    }
}
