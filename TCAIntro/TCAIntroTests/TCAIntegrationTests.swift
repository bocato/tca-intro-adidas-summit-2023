@testable import TCAIntro
import ComposableArchitecture
import XCTest

@MainActor
final class TCATests: XCTestCase {
    // Exhaustive testing
    func test_exhaustive_whenPokemonIsAddedToFavorites_itShouldUpdateTabAndFavorites() async throws {
        // Given
        let pokemonsMock: [PokemonData] = [
            .fixture(id: 1),
            .fixture(id: 2),
            .fixture(id: 3)
        ]
        let pokemonCards: [TCAPokemonCard.State] = pokemonsMock.map {
            TCAPokemonCard.State(pokemonData: $0)
        }
        
        let initialState: TCARoot.State = .init(
            tabsState: .init(
                listTab: .init(
                    pokemonCards: .init(uniqueElements: pokemonCards)
                ),
                favoritesTab: .init(favorites: [])
            )
        )
        let sut = TestStore(
            initialState: initialState,
            reducer: { TCARoot() }
        )
        
        // When
        await sut.send(.tabs(.list(.pokemonCard(id: 1, action: .onFavoriteTapped)))) {
            // Then
            $0.tabsState.listTab.pokemonCards[id: 1]?.isFavorite = true
        }
        await sut.receive(.tabs(.list(.pokemonCard(id: 1, action: .delegate(.onFavoriteToggled(true))))))
        // TODO: Continue!
    }
    
    // Exhaustive testing
    func test_NON_exhaustive_whenLoadPokemons_itShouldSetViewStateToLoaded_andFillTheList() async throws {
        // Given
        let pokemonDataFetcherStub = PokemonDataFetcherStub()
        let pokemonsMock: [PokemonData] = [
            .fixture(id: 1),
            .fixture(id: 2),
            .fixture(id: 3)
        ]
        
        pokemonDataFetcherStub.fetchOriginalPokemonsResultToBeReturned = .success(pokemonsMock)
        
        let initialState: TCAPokemonList.State = .init()
        let sut = TestStore(
            initialState: initialState,
            reducer: { TCAPokemonList() },
            withDependencies: {
                $0.pokemonDataFetcher = pokemonDataFetcherStub
            }
        )
        sut.exhaustivity = .off(showSkippedAssertions: true)
        
        // When
        await sut.send(.loadPokemons) {
            $0.viewState = .loaded
            $0.pokemonCards = .init(
                uniqueElements: pokemonsMock.map {
                    TCAPokemonCard.State(pokemonData: $0)
                }
            )
        }
    }
}
