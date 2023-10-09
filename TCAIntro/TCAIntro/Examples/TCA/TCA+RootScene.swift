import Foundation
import SwiftUI
import Combine

final class TCARootSceneViewModel: ObservableObject {
    // MARK: - Properties
    @Published var selectedTab: Int = 0
    @Published private(set) var numberOfFavorites: Int = 0
    
    private var subscriptions: Set<AnyCancellable> = .init()
    
    // MARK: - Subflows
    
    @Published private(set) var pokemonListViewModel: TCAPokemonListViewModel = TCAPokemonListViewModel()
    @Published private(set) var favoritesViewModel: TCAFavoritesViewModel = TCAFavoritesViewModel()
    
    // MARK: - Initialization
    
    init() {
        print("RootSceneViewModel.init")
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

struct TCARootScene: View {
    @StateObject var viewModel: TCARootSceneViewModel

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            TCAPokemonListScene(viewModel: viewModel.pokemonListViewModel)
                .tabItem {
                    Label("Pokemons", systemImage: "1.circle")
                }
                .tag(0)
            
            TCAFavoritesScene(viewModel: viewModel.favoritesViewModel)
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
struct TCARootScene_Previews: PreviewProvider {
    static var previews: some View {
        TCARootScene(viewModel: .init())
    }
}
#endif
