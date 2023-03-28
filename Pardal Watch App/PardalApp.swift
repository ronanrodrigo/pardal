import SwiftUI

@main
struct Pardal_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            LapTrackViewFactory.make()
        }
    }
}
