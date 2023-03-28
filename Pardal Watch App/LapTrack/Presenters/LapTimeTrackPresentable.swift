import Combine
import SwiftUI

protocol LapTimeTrackPresentable: ObservableObject {
    var stopAction: () -> () { get set }
    var startAction: () -> () { get set }
    var prepareAction: () -> () { get set }
    var title: String { get }
    var action: () -> () { get }
    var actionName: String { get }
    var iconColor: Color { get }
    var iconName: String { get }
    func handle(_ state: TimeTrackState)
}

enum LapTimeTrackPresentableFactory {
    static func make() -> some LapTimeTrackPresentable {
        LapTimeTrackPresenter()
    }
}

private final class LapTimeTrackPresenter: LapTimeTrackPresentable {
    var stopAction: () -> () = {}
    var startAction: () -> () = {} { didSet {
        action = startAction
    }}
    var prepareAction: () -> () = {}
    @Published var actionName: String = ""
    @Published var action: () -> () = { }
    @Published var title: String = ""
    @Published var iconColor: Color = .accentColor
    @Published var iconName: String = ""

    func handle(_ state: TimeTrackState) {
        switch state {
        case let s as TimeTrackRunningState:
            actionName = "Stop"
            action = stopAction
            title = Self.formatDuration(s.time)
            iconColor = .white
            iconName = "stopwatch.fill"
        case is TimeTrackStoppedState, is TimeTrackStoppingState:
            actionName = "Start"
            action = startAction
            iconColor = .white
            iconName = "flag.checkered.2.crossed"
        default:
            actionName = "Start"
            action = startAction
            title = Self.formatDuration(0)
            iconColor = .yellow
            iconName = "flag.checkered.2.crossed"
        }
    }

    private static func formatDuration(_ time: TimeInterval) -> String {
        let seconds = Duration.seconds(time)
        let pattern = Duration.TimeFormatStyle.Pattern
            .minuteSecond(padMinuteToLength: 2, fractionalSecondsLength: 3)
        let style = Duration.TimeFormatStyle.time(pattern: pattern)
        return seconds.formatted(style)
    }
}
