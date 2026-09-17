import Foundation

@MainActor
public protocol TimerCancellation { func cancel() }
@MainActor
public protocol TimerScheduling {
    func schedule(at date: Date, action: @escaping @MainActor () -> Void) -> TimerCancellation
}
@MainActor
public final class SystemTimerScheduler: TimerScheduling {
    public init() {}
    public func schedule(at date: Date, action: @escaping @MainActor () -> Void) -> TimerCancellation {
        let timer = Timer(fire: date, interval: 0, repeats: false) { _ in
            Task { @MainActor in action() }
        }
        RunLoop.main.add(timer, forMode: .common)
        return SystemTimerCancellation(timer)
    }
}
@MainActor
private final class SystemTimerCancellation: TimerCancellation {
    let timer: Timer
    init(_ timer: Timer) { self.timer = timer }
    func cancel() { timer.invalidate() }
    deinit { timer.invalidate() }
}
