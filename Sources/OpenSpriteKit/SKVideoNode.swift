//// SKVideoNode.swift
//// OpenSpriteKit
////
//// Copyright (c) 2024 OpenSpriteKit contributors
//// Licensed under MIT License
//
//import Foundation
//#if canImport(AVFoundation)
//import AVFoundation
//#endif
//
///// A graphical element that plays video content.
/////
///// This class renders a video at a given size and location in your scene with no exposed player controls.
//open class SKVideoNode: SKNode, @unchecked Sendable {
//
//    // MARK: - Visual Properties
//
//    /// The point in the sprite that corresponds to the node's position.
//    ///
//    /// The default value is (0.5, 0.5), which indicates that the video is centered on its position.
//    open var anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
//
//    /// The dimensions of the video node, in points.
//    open var size: CGSize = .zero
//
//    // MARK: - Internal Properties
//
//    /// The URL of the video file.
//    private var videoURL: URL?
//
//    /// The name of the video file in the bundle.
//    private var videoFileName: String?
//
//    #if canImport(AVFoundation)
//    /// The AVPlayer used for playback.
//    private var player: AVPlayer?
//    #endif
//
//    // MARK: - Initializers
//
//    /// Creates a new video node.
//    public override init() {
//        super.init()
//    }
//
//    #if canImport(AVFoundation)
//    /// Initializes a video node using an existing AVPlayer object.
//    ///
//    /// - Parameter player: An existing AVPlayer object that provides the video content.
//    public init(avPlayer player: AVPlayer) {
//        self.player = player
//        super.init()
//    }
//    #endif
//
//    /// Initializes a video node using a video file stored in the app bundle.
//    ///
//    /// - Parameter videoFile: The name of a video file stored in the app bundle.
//    public init(fileNamed videoFile: String) {
//        self.videoFileName = videoFile
//        super.init()
//        loadVideo(named: videoFile)
//    }
//
//    /// Initializes a video node using a URL.
//    ///
//    /// - Parameter url: A URL that points to a video file.
//    public init(url: URL) {
//        self.videoURL = url
//        super.init()
//        loadVideo(from: url)
//    }
//
//    /// Initializes a video node using a video file stored in the app bundle.
//    ///
//    /// - Parameter videoFile: The name of a video file stored in the app bundle.
//    @available(*, deprecated, message: "Use init(fileNamed:) instead")
//    public convenience init(videoFileNamed videoFile: String) {
//        self.init(fileNamed: videoFile)
//    }
//
//    /// Initializes a video node using a URL that points to a video file.
//    ///
//    /// - Parameter url: A URL that points to a video file.
//    @available(*, deprecated, message: "Use init(url:) instead")
//    public convenience init(videoURL url: URL) {
//        self.init(url: url)
//    }
//
//    // MARK: - Playback Control
//
//    /// Starts video playback.
//    open func play() {
//        #if canImport(AVFoundation)
//        player?.play()
//        #endif
//    }
//
//    /// Pauses video playback.
//    open func pause() {
//        #if canImport(AVFoundation)
//        player?.pause()
//        #endif
//    }
//
//    // MARK: - Private Methods
//
//    /// Loads a video from the app bundle.
//    ///
//    /// - Parameter filename: The name of the video file.
//    private func loadVideo(named filename: String) {
//        let nameWithoutExtension = (filename as NSString).deletingPathExtension
//        let fileExtension = (filename as NSString).pathExtension
//
//        var url: URL?
//
//        if !fileExtension.isEmpty {
//            url = Bundle.main.url(forResource: nameWithoutExtension, withExtension: fileExtension)
//        } else {
//            // Try common video extensions
//            let extensions = ["mp4", "mov", "m4v"]
//            for ext in extensions {
//                if let found = Bundle.main.url(forResource: filename, withExtension: ext) {
//                    url = found
//                    break
//                }
//            }
//        }
//
//        if let videoURL = url {
//            self.videoURL = videoURL
//            loadVideo(from: videoURL)
//        }
//    }
//
//    /// Loads a video from a URL.
//    ///
//    /// - Parameter url: The URL of the video file.
//    private func loadVideo(from url: URL) {
//        #if canImport(AVFoundation)
//        let playerItem = AVPlayerItem(url: url)
//        player = AVPlayer(playerItem: playerItem)
//        #endif
//    }
//
//    // MARK: - Frame Calculation
//
//    /// The calculated frame of the video node.
//    open override var frame: CGRect {
//        let origin = CGPoint(
//            x: position.x - size.width * anchorPoint.x,
//            y: position.y - size.height * anchorPoint.y
//        )
//        return CGRect(origin: origin, size: size)
//    }
//}
