import Combine

protocol LapTimeStopTrackInteractable {
    func stop()
}

enum LapTimeStopTrackInteractableFactory {
    static func make<P: LapTimeTrackPresentable>(_ stateGateway: LapTimeTrackStateGateway, _ presenter: P) -> LapTimeStopTrackInteractable {
        return LapTimeStopTrackInteractor(stateGateway: stateGateway, presenter: presenter)
    }
}

private final class LapTimeStopTrackInteractor<Presenter: LapTimeTrackPresentable>: LapTimeStopTrackInteractable {
    private var cancellable: AnyCancellable?
    let stateGateway: LapTimeTrackStateGateway
    let presenter: Presenter

    init(stateGateway: LapTimeTrackStateGateway, presenter: Presenter) {
        self.stateGateway = stateGateway
        self.presenter = presenter
    }

    func stop() {
        stateGateway.stop()
        presenter.handle(stoppedState)
    }
}
