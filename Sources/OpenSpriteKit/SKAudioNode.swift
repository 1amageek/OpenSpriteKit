// SKAudioNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation
#if canImport(AVFAudio)
import AVFAudio
#endif

/// A node that plays audio.
///
/// A `SKAudioNode` object is used to add audio to a scene. The sounds are played automatically
/// using AVFoundation, and the node can optionally add 3D spatial audio effects to the audio
/// when it is played.
///
/// By default, `SKAudioNode` objects are positional, i.e. their `isPositional` property is set
/// to `true`. If you add an audio node to a scene with a `listener` set, SpriteKit will set the
/// stereo balance and the volume based on the relative positions of the two nodes.
open class SKAudioNode: SKNode, @unchecked Sendable {

    // MARK: - Audio Properties

    #if canImport(AVFAudio)
    /// The audio node's current audio asset.
    open var avAudioNode: AVAudioNode?
    #endif

    /// A Boolean property that indicates whether the node's audio is altered based on
    /// the position of the node.
    ///
    /// When set to `true`, SpriteKit adjusts the audio's stereo balance and volume based
    /// on the node's position relative to the scene's listener. The default value is `true`.
    open var isPositional: Bool = true

    /// A Boolean value that indicates whether the audio should play in a loop when the
    /// node is added to the scene.
    ///
    /// When set to `true`, the audio automatically begins playing when the node is added
    /// to a scene and loops continuously. The default value is `true`.
    open var autoplayLooped: Bool = true

    // MARK: - Internal Properties

    /// The URL of the audio file.
    private var audioURL: URL?

    /// The name of the audio file in the bundle.
    private var audioFileName: String?

    // MARK: - Initializers

    /// Creates a new audio node.
    public override init() {
        super.init()
    }

    #if canImport(AVFAudio)
    /// Initializes an audio node from an AVFoundation audio node.
    ///
    /// - Parameter node: An AVFoundation audio node that provides the audio content.
    public init(avAudioNode node: AVAudioNode?) {
        self.avAudioNode = node
        super.init()
    }
    #endif

    /// Initializes an audio node from an audio asset with the specified filename.
    ///
    /// - Parameter filename: The name of an audio file stored in the app bundle.
    public convenience init(fileNamed filename: String) {
        self.init()
        self.audioFileName = filename
        loadAudio(named: filename)
    }

    /// Initializes an audio node from an audio asset with the specified URL.
    ///
    /// - Parameter url: A URL that points to an audio file.
    public convenience init(url: URL) {
        self.init()
        self.audioURL = url
        loadAudio(from: url)
    }

    // MARK: - Private Methods

    /// Loads audio from the app bundle.
    ///
    /// - Parameter filename: The name of the audio file.
    private func loadAudio(named filename: String) {
        let nameWithoutExtension = (filename as NSString).deletingPathExtension
        let fileExtension = (filename as NSString).pathExtension

        var url: URL?

        if !fileExtension.isEmpty {
            url = Bundle.main.url(forResource: nameWithoutExtension, withExtension: fileExtension)
        } else {
            // Try common audio extensions
            let extensions = ["mp3", "wav", "aac", "m4a", "caf", "aiff"]
            for ext in extensions {
                if let found = Bundle.main.url(forResource: filename, withExtension: ext) {
                    url = found
                    break
                }
            }
        }

        if let audioURL = url {
            self.audioURL = audioURL
            loadAudio(from: audioURL)
        }
    }

    /// Loads audio from a URL.
    ///
    /// - Parameter url: The URL of the audio file.
    private func loadAudio(from url: URL) {
        #if canImport(AVFAudio)
        do {
            // Validate the audio file exists and is readable
            _ = try AVAudioFile(forReading: url)
            let playerNode = AVAudioPlayerNode()
            self.avAudioNode = playerNode
            // Note: Actual audio engine connection would happen when added to scene
        } catch {
            // Audio loading failed
            self.avAudioNode = nil
        }
        #endif
    }
}
