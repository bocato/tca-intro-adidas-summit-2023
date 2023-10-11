@testable import TCAIntro
import Combine
import XCTest

final class MVVMTests: XCTestCase {
    func test_whenPokemonIsAddedToFavorites_itShouldUpdateTabAndFavorites() async throws {
        // Given
        let pokemonDataFetcherStub: PokemonDataFetcherStub = .init()
        pokemonDataFetcherStub.fetchOriginalPokemonsResultToBeReturned = .success(
            [
                .fixture(id: 1),
                .fixture(id: 2),
                .fixture(id: 3)
            ]
        )
        
        let pokemonListViewModel: PokemonListViewModel = .init(
            pokemonDataFetcher: pokemonDataFetcherStub,
            logger: DummyLogger()
        )
        let favoritesViewModel: FavoritesViewModel = .init(
            pokemonDataFetcher: pokemonDataFetcherStub,
            logger: DummyLogger()
        )
        let sut: RootSceneViewModel = .init(
            pokemonListViewModel: pokemonListViewModel,
            favoritesViewModel: favoritesViewModel
        )
        
        var subscriptions: Set<AnyCancellable> = .init()
        
        let numberOfFavoritesExpectation = expectation(description: "numberOfFavoritesReceived")
        numberOfFavoritesExpectation.expectedFulfillmentCount = 2
        numberOfFavoritesExpectation.assertForOverFulfill = false
        var numberOfFavoritesReceived: Int?
        sut.$numberOfFavorites.sink {
            numberOfFavoritesReceived = $0
            numberOfFavoritesExpectation.fulfill()
        }.store(in: &subscriptions)
        
        let favoritesExpectation = expectation(description: "favoritesReceived")
        favoritesExpectation.expectedFulfillmentCount = 2
        favoritesExpectation.assertForOverFulfill = false
        var favoritesReceived: [PokemonData]?
        sut.favoritesViewModel.$favorites.sink {
            favoritesReceived = $0
            favoritesExpectation.fulfill()
        }.store(in: &subscriptions)
        
        // When
        await sut.pokemonListViewModel.loadPokemons()
        sut.pokemonListViewModel.cardViewModels.first?.toggleFavorite()
        
        // Then
        await fulfillment(of: [numberOfFavoritesExpectation, favoritesExpectation])
        
        XCTAssertEqual(numberOfFavoritesReceived, 1)
        XCTAssertEqual(favoritesReceived, [.fixture(id: 1)])
    }
}
