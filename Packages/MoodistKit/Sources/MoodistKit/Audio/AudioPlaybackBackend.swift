//
//  AudioPlaybackBackend.swift
//  MoodistMac
//

import Foundation

@MainActor
public protocol AudioPlaybackBackend {
    var isPlaying: Bool { get }
    var onFailure: ((String) -> Void)? { get set }
    @discardableResult
    func load(sound: Sound) -> Bool
    func setVolume(soundId: String, volume: Double, globalVolume: Double)
    func setVolume(soundId: String, volume: Double, globalVolume: Double, fadeDuration: TimeInterval)
    func play(soundId: String)
    func pause(soundId: String)
    func unload(soundId: String)
    func unloadAll()
    func playAll(ids: [String])
    func pauseAll(ids: [String])
    func updateVolumes(state: [String: SoundStateItem], globalVolume: Double)
    func fadeOutAndUnload(soundId: String, duration: TimeInterval)
    func scheduleOutgoingCleanup(after duration: TimeInterval)
    func cancelCrossfadeAndCleanup()
}
