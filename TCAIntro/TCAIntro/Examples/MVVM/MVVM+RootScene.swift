import Foundation
import SwiftUI
import Combine

final class RootSceneViewModel: ObservableObject {
    // MARK: - Properties
    @Published var selectedTab: Int = 0
    @Published private(set) var numberOfFavorites: Int = 0
    
    private var subscriptions: Set<AnyCancellable> = .init()
    
    // MARK: - Subflows
    
    @Published private(set) var pokemonListViewModel: PokemonListViewModel
    @Published private(set) var favoritesViewModel: FavoritesViewModel
    
    // MARK: - Initialization
    
    init(
        pokemonListViewModel: PokemonListViewModel,
        favoritesViewModel: FavoritesViewModel
    ) {
        self.pokemonListViewModel = pokemonListViewModel
        self.favoritesViewModel = favoritesViewModel
        bind()
    }
    
    // MARK: - Binding
    
    private var didBindCardViewModels = false
    
    private func bind() {
        favoritesViewModel.$favorites.removeDuplicates().sink { data in
            self.pokemonListViewModel.cardViewModels.forEach { cardViewModel in
                let isFavorite = data.contains { $0.id == cardViewModel.id }
                cardViewModel.isFavorite = isFavorite
            }
            if self.numberOfFavorites != data.count {
                self.numberOfFavorites = data.count
            }
        }.store(in: &subscriptions)
        
        pokemonListViewModel.actions = .init(
            onFavoriteStateChanged: { [weak self] pokemonData, isFavorite in
                if isFavorite {
                    self?.favoritesViewModel
                        .addToFavorite(pokemonData)
                } else {
                    self?.favoritesViewModel
                        .removeFromFavorites(pokemonData)
                }
            }
        )
    }
    
    // MARK: - Public API
    
    func resetFavoritesButtonTapped() {
        favoritesViewModel.purgeFavorites()
    }
}

struct RootScene: View {
    @StateObject var viewModel: RootSceneViewModel

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            PokemonListScene(viewModel: viewModel.pokemonListViewModel)
                .tabItem {
                    Label("Pokemons", systemImage: "1.circle")
                }
                .tag(0)
            
            FavoritesScene(viewModel: viewModel.favoritesViewModel)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Reset Favorites") {
                            viewModel.resetFavoritesButtonTapped()
                        }
                    }
                }
                .tabItem {
                    Label {
                        Text("Favorites (\(viewModel.numberOfFavorites))")
                    } icon: {
                        Image(systemName: "heart.fill")
                    }
                }
                .tag(1)
        }
    }
}

#if DEBUG
struct RootScene_Previews: PreviewProvider {
    static var previews: some View {
        RootScene(viewModel: .init())
    }
}
#endif
