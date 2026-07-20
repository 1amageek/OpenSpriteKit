// SKAudioNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation
#if canImport(AVFAudio)
import AVFAudio
#endif
#if arch(wasm32)
import JavaScriptKit
#endif

internal enum SKAudioPlaybackState: Equatable {
    case idle
    case ready
    case playing
    case paused
    case stopped
    case failed(String)
}

/// A node that plays audio.
///
/// A `SKAudioNode` object is used to add audio to a scene. The sounds are played automatically
/// using AVFoundation, and the node can optionally add 3D spatial audio effects to the audio
/// when it is played.
///
/// By default, `SKAudioNode` objects are positional, i.e. their `isPositional` property is set
/// to `true`. If you add an audio node to a scene with a `listener` set, SpriteKit will set the
/// stereo balance and the volume based on the relative positions of the two nodes.
open class SKAudioNode: SKNode {

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
    open var autoplayLooped: Bool = true {
        didSet {
            #if canImport(AVFAudio)
            audioPlayer?.numberOfLoops = autoplayLooped ? -1 : 0
            #elseif arch(wasm32)
            browserAudio?.loop = .boolean(autoplayLooped)
            #endif
        }
    }

    // MARK: - Playback State

    internal private(set) var playbackState: SKAudioPlaybackState = .idle
    internal private(set) var volume: Float = 1
    internal private(set) var playbackRate: Float = 1
    internal private(set) var stereoPan: Float = 0
    internal private(set) var obstruction: Float = 0
    internal private(set) var occlusion: Float = 0
    internal private(set) var reverbBlend: Float = 0

    // MARK: - Internal Properties

    /// The URL of the audio file.
    private var audioURL: URL?

    /// The name of the audio file in the bundle.
    private var audioFileName: String?

    #if canImport(AVFAudio)
    private var audioPlayer: AVAudioPlayer?
    #endif

    #if arch(wasm32)
    private var browserAudio: JSObject?
    #endif

    // MARK: - Initializers

    /// Creates a new audio node.
    public override init() {
        super.init()
    }

    // MARK: - Copying

    /// Creates a copy of this audio node.
    open override func copy() -> SKNode {
        let audioCopy = SKAudioNode()
        audioCopy._copyNodeProperties(from: self)
        return audioCopy
    }

    /// Internal helper to copy SKAudioNode properties.
    internal override func _copyNodeProperties(from node: SKNode) {
        super._copyNodeProperties(from: node)
        guard let audioNode = node as? SKAudioNode else { return }

        self.isPositional = audioNode.isPositional
        self.autoplayLooped = audioNode.autoplayLooped
        self.audioURL = audioNode.audioURL
        self.audioFileName = audioNode.audioFileName
        self.volume = audioNode.volume
        self.playbackRate = audioNode.playbackRate
        self.stereoPan = audioNode.stereoPan
        self.obstruction = audioNode.obstruction
        self.occlusion = audioNode.occlusion
        self.reverbBlend = audioNode.reverbBlend
        #if canImport(AVFAudio)
        self.avAudioNode = audioNode.avAudioNode
        #endif
        if let audioURL {
            loadAudio(from: audioURL)
        } else if let audioFileName {
            loadAudio(named: audioFileName)
        } else {
            #if canImport(AVFAudio)
            playbackState = avAudioNode == nil ? .idle : .ready
            #else
            playbackState = .idle
            #endif
        }
        applyMixingState()
    }

    #if canImport(AVFAudio)
    /// Initializes an audio node from an AVFoundation audio node.
    ///
    /// - Parameter node: An AVFoundation audio node that provides the audio content.
    public init(avAudioNode node: AVAudioNode?) {
        self.avAudioNode = node
        self.playbackState = node == nil ? .idle : .ready
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
        #if arch(wasm32)
        configureBrowserAudio(source: filename)
        return
        #else
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
        } else {
            playbackState = .failed("Audio resource not found: \(filename)")
        }
        #endif
    }

    /// Loads audio from a URL.
    ///
    /// - Parameter url: The URL of the audio file.
    private func loadAudio(from url: URL) {
        #if canImport(AVFAudio)
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.enableRate = true
            player.numberOfLoops = autoplayLooped ? -1 : 0
            player.volume = volume
            player.rate = playbackRate
            player.pan = stereoPan
            guard player.prepareToPlay() else {
                playbackState = .failed("Audio decoder could not prepare: \(url.absoluteString)")
                return
            }
            audioPlayer = player
            let playerNode = AVAudioPlayerNode()
            self.avAudioNode = playerNode
            playbackState = .ready
        } catch {
            self.avAudioNode = nil
            self.audioPlayer = nil
            playbackState = .failed(error.localizedDescription)
        }
        #elseif arch(wasm32)
        configureBrowserAudio(source: url.absoluteString)
        #else
        playbackState = .failed("Audio playback is unavailable on this platform")
        #endif
    }

    #if arch(wasm32)
    private func configureBrowserAudio(source: String) {
        guard let audioConstructor = JSObject.global.Audio.function else {
            playbackState = .failed("Browser Audio API is unavailable")
            return
        }
        let audio = audioConstructor.new(source)
        browserAudio = audio
        audio.loop = .boolean(autoplayLooped)
        audio.volume = .number(Double(effectiveVolume))
        audio.playbackRate = .number(Double(playbackRate))
        playbackState = .ready
    }
    #endif

    internal var isPlaybackActive: Bool {
        #if canImport(AVFAudio)
        return audioPlayer?.isPlaying ?? false
        #elseif arch(wasm32)
        guard let browserAudio else { return false }
        return browserAudio.paused.boolean == false && browserAudio.ended.boolean != true
        #else
        return false
        #endif
    }

    internal func playAudio() {
        #if canImport(AVFAudio)
        guard let audioPlayer else {
            if case .failed = playbackState { return }
            playbackState = .failed("No decoded audio asset is available")
            return
        }
        audioPlayer.numberOfLoops = autoplayLooped ? -1 : 0
        guard audioPlayer.play() else {
            playbackState = .failed("Audio playback could not start")
            return
        }
        playbackState = .playing
        #elseif arch(wasm32)
        guard let browserAudio, let play = browserAudio.play.function else {
            if case .failed = playbackState { return }
            playbackState = .failed("No browser audio asset is available")
            return
        }
        browserAudio.loop = .boolean(autoplayLooped)
        _ = play()
        playbackState = .playing
        #else
        playbackState = .failed("Audio playback is unavailable on this platform")
        #endif
    }

    internal func pauseAudio() {
        #if canImport(AVFAudio)
        audioPlayer?.pause()
        #elseif arch(wasm32)
        _ = browserAudio?.pause.function?()
        #endif
        if case .playing = playbackState {
            playbackState = .paused
        }
    }

    internal func stopAudio() {
        #if canImport(AVFAudio)
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        #elseif arch(wasm32)
        _ = browserAudio?.pause.function?()
        browserAudio?.currentTime = .number(0)
        #endif
        playbackState = .stopped
    }

    internal func setVolume(_ value: Float) {
        volume = min(max(value, 0), 1)
        applyMixingState()
    }

    internal func setPlaybackRate(_ value: Float) {
        playbackRate = min(max(value, 0.25), 4)
        applyMixingState()
    }

    internal func setStereoPan(_ value: Float) {
        stereoPan = min(max(value, -1), 1)
        applyMixingState()
    }

    internal func setObstruction(_ value: Float) {
        obstruction = min(max(value, 0), 1)
        applyMixingState()
    }

    internal func setOcclusion(_ value: Float) {
        occlusion = min(max(value, 0), 1)
        applyMixingState()
    }

    internal func setReverbBlend(_ value: Float) {
        reverbBlend = min(max(value, 0), 1)
        applyMixingState()
    }

    private var effectiveVolume: Float {
        volume * (1 - obstruction) * (1 - occlusion)
    }

    private func applyMixingState() {
        #if canImport(AVFAudio)
        audioPlayer?.volume = effectiveVolume
        audioPlayer?.rate = playbackRate
        audioPlayer?.pan = stereoPan
        if let mixing = avAudioNode as? AVAudio3DMixing {
            mixing.obstruction = obstruction
            mixing.occlusion = occlusion
            mixing.reverbBlend = reverbBlend
        }
        #elseif arch(wasm32)
        browserAudio?.volume = .number(Double(effectiveVolume))
        browserAudio?.playbackRate = .number(Double(playbackRate))
        #endif
    }
}
