import Combine

protocol LapTimeTrackStateGateway: AnyObject {
    var state: AnyPublisher<TimeTrackState, Never> { get }
    func start()
    func stop()
    func prepare()
    func update(to state: TimeTrackState)
}

enum LapTimeTrackStateGatewayFactory {
    static func make() -> LapTimeTrackStateGateway {
        let cronometerGateway = CronometerGatewayFactory.make()
        let gateway = LapTimeTrackStateMachineGateway(cronometerGateway: cronometerGateway)
        BaseTrackState.gateway = gateway
        return gateway
    }
}

private final class LapTimeTrackStateMachineGateway: LapTimeTrackStateGateway {
    var state: AnyPublisher<TimeTrackState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    private var cancellable: AnyCancellable?
    private let stateSubject = CurrentValueSubject<TimeTrackState, Never>(idleState)
    private let cronometerGateway: CronometerGateway

    init(cronometerGateway: CronometerGateway) {
        self.cronometerGateway = cronometerGateway
        update(to: idleState)
    }

    func start() {
        stateSubject.value.start()
    }

    func stop() {
        stateSubject.value.stop()
    }

    func prepare() {
        stateSubject.value.prepare()
    }

    func update(to state: TimeTrackState) {
        stateSubject.value = state
        if state is TimeTrackStartingState {
            startCronometer()
        } else if state is TimeTrackStoppingState {
            stopCronometer()
        }
    }

    private func startCronometer() {
        cancellable = cronometerGateway.start().sink { [weak self] in
            self?.update(to: runningState($0))
        }
    }

    private func stopCronometer() {
        cronometerGateway.stop()
        update(to: stoppedState)
    }
}
