import ComposableArchitecture
import SwiftUI

// Namespaces
enum MVVM {}
enum TCA {}

@main
struct TCAIntroApp: App {
    var body: some Scene {
        WindowGroup {
            RootScene(viewModel: .init())
        }
    }
}
