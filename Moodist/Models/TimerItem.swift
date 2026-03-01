//
//  TimerItem.swift
//  MoodistMac
//
//  Temporizador: nombre, duración, estado (idle/running/paused).
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
    /// Estado en tiempo de ejecución (no se persiste).
    var state: TimerState = .idle

    /// Calcula cuántos segundos quedan según el estado actual del temporizador.
    var remainingSeconds: Int {
        switch state {
        case .idle: return durationSeconds
        case .running(let end): return max(0, Int(end.timeIntervalSinceNow))
        case .paused(let sec): return sec
        }
    }

    /// Indica si el temporizador está activo.
    var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    enum CodingKeys: String, CodingKey {
        case id, name, durationSeconds
    }

    /// Inicializador principal que valida la duración mínima y permite definir el estado inicial en memoria.
    init(id: UUID = UUID(), name: String, durationSeconds: Int, state: TimerState = .idle) {
        self.id = id
        self.name = name
        self.durationSeconds = max(1, durationSeconds)
        self.state = state
    }

    /// Decodifica campos persistentes, siempre empezando en estado idle porque el estado no se guarda.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        durationSeconds = try c.decode(Int.self, forKey: .durationSeconds)
        state = .idle
    }

    /// Codifica solo los metadatos persistentes (sin estado en memoria).
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(durationSeconds, forKey: .durationSeconds)
    }

    /// La igualdad ignora el estado en memoria porque cada instancia puede llevar su propio estado.
    static func == (lhs: TimerItem, rhs: TimerItem) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.durationSeconds == rhs.durationSeconds
    }
}
