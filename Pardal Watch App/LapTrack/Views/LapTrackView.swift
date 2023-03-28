import SwiftUI
import Combine

enum LapTrackViewFactory {
    static func make() -> some View {
        let stateGateway = LapTimeTrackStateGatewayFactory.make()
        let presenter = LapTimeTrackPresentableFactory.make()
        let stopInteractor = LapTimeStopTrackInteractableFactory.make(stateGateway, presenter)
        let startInteractor = LapTimeStartTrackInteractableFactory.make(stateGateway, presenter)
        let prepareInteractor = LapTimePrepareTrackingInteractableFactory.make(stateGateway, presenter)
        presenter.stopAction = stopInteractor.stop
        presenter.startAction = startInteractor.start
        presenter.prepareAction = prepareInteractor.prepare
        return LapTrackView(presenter: presenter)
    }
}

private struct LapTrackView<Presenter: LapTimeTrackPresentable>: View {
    @ObservedObject var presenter: Presenter
    @ScaledMetric var height: CGFloat = 15
    var body: some View {
        VStack {
            Image(systemName: presenter.iconName)
                .imageScale(.large)
                .foregroundColor(presenter.iconColor)
                .frame(height: height, alignment: .center)
            Text(presenter.title)
                .font(.title)
                .monospacedDigit()
            Button(presenter.actionName, action: presenter.action)
        }
        .onAppear(perform: presenter.prepareAction)
        .padding()
    }
}

struct LapTrackViewView_Previews: PreviewProvider {
    static var previews: some View {
        LapTrackViewFactory.make()
    }
}
