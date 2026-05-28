//
//  AudioSpatialTypes.swift
//  MoodistMac
//

import Foundation

struct AudioPosition: Equatable {
    let x: Float
    let y: Float
    let z: Float

    static let center = AudioPosition(x: 0, y: 0, z: 0)
}

enum AudioRoutingMode: Equatable {
    case mainMixer
    case positioned(AudioPosition)
    case channel(index: Int)
}

enum SpatialRenderMode: Equatable {
    case disabled
    case environment
}
