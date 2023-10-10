import ComposableArchitecture
import SwiftUI

// Namespaces
enum MVVM {}
enum TCA {}

@main
struct TCAIntroApp: App {
    var pokemonDataFetcher: PokemonDataFetching = PokemonDataFetcher()
    var logger: LoggerProtocol = DefaultLogger()
    
    var body: some Scene {
        WindowGroup {
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
}
