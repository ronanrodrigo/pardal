import Combine
import Foundation

protocol CronometerGateway {
    func start() -> AnyPublisher<TimeInterval, Never>
    func stop()
}

enum CronometerGatewayFactory {
    static func make() -> CronometerGateway {
        return CronometerCounterGateway()
    }
}

private final class CronometerCounterGateway: CronometerGateway {
    private let timerPublisher = Timer.publish(every: 0.001, tolerance: 0.001, on: .main, in: .common).autoconnect()

    func start() -> AnyPublisher<TimeInterval, Never> {
        let startTime = Date()
        return timerPublisher
            .map { $0.timeIntervalSince(startTime) }
            .eraseToAnyPublisher()
    }

    func stop() {
        timerPublisher.upstream.connect().cancel()
    }
}
