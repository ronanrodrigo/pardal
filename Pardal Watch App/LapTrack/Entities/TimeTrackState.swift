import Foundation

protocol TimeTrackState {
    static var gateway: LapTimeTrackStateGateway? { get set }
    func prepare()
    func start()
    func stop()
}

class BaseTrackState: TimeTrackState {
    fileprivate init() { }
    static weak var gateway: LapTimeTrackStateGateway?
    func prepare() { }
    func start() { }
    func stop() { }
}

final class TimeTrackStartingState: BaseTrackState { }

final class TimeTrackRunningState: BaseTrackState {
    var time: TimeInterval
    fileprivate init(_ time: TimeInterval) {
        self.time = time
    }
    override func stop() {
        Self.gateway?.update(to: stoppingState)
    }
}

final class TimeTrackStoppingState: BaseTrackState { }

final class TimeTrackStoppedState: BaseTrackState {
    override func start() {
        Self.gateway?.update(to: startingState)
    }
}

final class TimeTrackIdleState: BaseTrackState {
    override func start() {
        Self.gateway?.update(to: startingState)
    }
}

let idleState = TimeTrackIdleState()
let stoppingState = TimeTrackStoppingState()
let stoppedState = TimeTrackStoppedState()
let startingState = TimeTrackStartingState()
let runningState = TimeTrackRunningState.init
