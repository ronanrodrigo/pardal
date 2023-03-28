import Combine

protocol LapTimeStartTrackInteractable {
    func start()
}

enum LapTimeStartTrackInteractableFactory {
    static func make<P: LapTimeTrackPresentable>(_ stateGateway: LapTimeTrackStateGateway, _ presenter: P) -> LapTimeStartTrackInteractable {
        LapTimeStartTrackInteractor(stateGateway: stateGateway, presenter: presenter)
    }
}

private final class LapTimeStartTrackInteractor<Presenter: LapTimeTrackPresentable>: LapTimeStartTrackInteractable {
    private var cancellable: AnyCancellable?
    let stateGateway: LapTimeTrackStateGateway
    let presenter: Presenter

    init(stateGateway: LapTimeTrackStateGateway, presenter: Presenter) {
        self.stateGateway = stateGateway
        self.presenter = presenter
    }

    func start() {
        stateGateway.start()
        cancellable = stateGateway.state.sink { [weak self] in
            self?.presenter.handle($0)
        }
    }
}
