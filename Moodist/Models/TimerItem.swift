//
//  TimerItem.swift
//  MoodistMac
//
//  Timer: name, duration, and runtime state.
//

import Foundation

enum TimerState: Equatable {
    case idle
    case running(endDate: Date)
    case paused(remainingSeconds: Int)
}

struct TimerItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var durationSeconds: Int
    /// Runtime state, not persisted.
    var state: TimerState = .idle

    /// Calculates remaining seconds from the current timer state.
    var remainingSeconds: Int {
        switch state {
        case .idle: return durationSeconds
        case .running(let end): return max(0, Int(end.timeIntervalSinceNow))
        case .paused(let sec): return sec
        }
    }

    /// Indicates whether the timer is running.
    var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    enum CodingKeys: String, CodingKey {
        case id, name, durationSeconds
    }

    /// Main initializer that validates minimum duration and accepts an initial in-memory state.
    init(id: UUID = UUID(), name: String, durationSeconds: Int, state: TimerState = .idle) {
        self.id = id
        self.name = name
        self.durationSeconds = max(1, durationSeconds)
        self.state = state
    }

    /// Decodes persisted fields and always starts idle because runtime state is not saved.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        durationSeconds = try c.decode(Int.self, forKey: .durationSeconds)
        state = .idle
    }

    /// Encodes only persisted metadata, without runtime state.
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(durationSeconds, forKey: .durationSeconds)
    }

    /// Equality ignores runtime state because each instance may carry its own state.
    static func == (lhs: TimerItem, rhs: TimerItem) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.durationSeconds == rhs.durationSeconds
    }
}
