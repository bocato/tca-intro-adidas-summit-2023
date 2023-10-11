import ComposableArchitecture
import SwiftUI

@main
struct TCAIntroApp: App {
    var pokemonDataFetcher: PokemonDataFetching = PokemonDataFetcher()
    var logger: LoggerProtocol = DefaultLogger()
    
    var body: some Scene {
        WindowGroup {
            if !_XCTIsTesting {
                rootScene()
            } else {
                Text("Testing...")
            }
        }
    }
    
    @ViewBuilder
    private func rootScene() -> some View {
        //            RootScene(
        //                viewModel: .init(
        //                    pokemonListViewModel: .init(
        //                        pokemonDataFetcher: pokemonDataFetcher
        //                    ),
        //                    favoritesViewModel: .init(
        //                        pokemonDataFetcher: pokemonDataFetcher,
        //                        logger: logger
        //                    )
        //                )
        //            )
        TCARootScene(
            store: .init(
                initialState: .init(),
                reducer: { TCARoot() }
            )
        )
    }
}
