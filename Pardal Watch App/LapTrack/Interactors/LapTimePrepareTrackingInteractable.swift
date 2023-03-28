import Combine

protocol LapTimePrepareTrackingInteractable {
    func prepare()
}

enum LapTimePrepareTrackingInteractableFactory {
    static func make<P: LapTimeTrackPresentable>(_ stateGateway: LapTimeTrackStateGateway, _ presenter: P) -> LapTimePrepareTrackingInteractable {
        LapTimePrepareTrackingInteractor(stateGateway: stateGateway, presenter: presenter)
    }
}

private final class LapTimePrepareTrackingInteractor<Presenter: LapTimeTrackPresentable>: LapTimePrepareTrackingInteractable {
    private var cancellable: AnyCancellable?
    let stateGateway: LapTimeTrackStateGateway
    let presenter: Presenter

    init(stateGateway: LapTimeTrackStateGateway, presenter: Presenter) {
        self.stateGateway = stateGateway
        self.presenter = presenter
    }

    func prepare() {
        stateGateway.prepare()
        cancellable = stateGateway.state
            .first { $0 is TimeTrackIdleState }
            .sink { [weak self] in
                self?.presenter.handle($0)
            }
    }
}
