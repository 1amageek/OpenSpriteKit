// SKVideoNode.swift
// OpenSpriteKit

import Foundation

/// A graphical element that plays video content.
open class SKVideoNode: SKNode {
    /// The point in the sprite that corresponds to the node's position.
    open var anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)

    /// The dimensions of the video node, in points.
    open var size: CGSize = .zero

    /// The URL backing the video source, when known.
    public private(set) var videoURL: URL?

    /// The bundle resource name backing the video source, when known.
    public private(set) var videoFileName: String?

    /// Whether playback is currently requested.
    public private(set) var isPlaying: Bool = false

    public override init() {
        super.init()
    }

    public init(fileNamed videoFile: String) {
        videoFileName = videoFile
        super.init()
    }

    public init(url: URL) {
        videoURL = url
        super.init()
    }

    open func play() {
        isPlaying = true
    }

    open func pause() {
        isPlaying = false
    }
}
