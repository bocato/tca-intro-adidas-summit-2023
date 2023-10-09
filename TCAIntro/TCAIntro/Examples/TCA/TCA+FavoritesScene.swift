import Foundation
import Combine
import SwiftUI

final class TCAFavoritesViewModel: ObservableObject {
    // MARK: - Dependencies
    
    var logger: LoggerProtocol = DefaultLogger()
    
    // MARK: - Properties
    
    @Published var favorites: [PokemonData] = [] {
        didSet { setupCardViewModels() }
    }
    @Published private(set) var cardViewModels: [TCAPokemonCardViewModel] = [] {
        didSet { bindCardViewModels() }
    }
    
    enum Route: Equatable {
        case pokemonDetails
    }
    @Published private(set) var route: Route?
    
    private var subscriptions: Set<AnyCancellable> = .init()
    
    // MARK: - Child Flows
    
    @Published private(set) var pokemonDetailsViewModel: TCAPokemonDetailsViewModel?
    
    // MARK: - Intialization
    
    init() {
        print("FavoritesViewModel.init")
    }
    
    // MARK: - Binding
    
    private func bindCardViewModels() {
        guard !cardViewModels.isEmpty else { return }
        cardViewModels.forEach { cardViewModel in
            cardViewModel.$evolutionsRequestError.sink { [logger] error in
                guard let error else { return }
                logger.logError(error)
            }
            .store(in: &subscriptions)
        }
    }
    
    // MARK: - Public API
    
    private func setupCardViewModels() {
        cardViewModels = favorites.map { pokemon in
            TCAPokemonCardViewModel(
                pokemonData: pokemon,
                configs: .init(
                    loadEvolutionsEnabled: false,
                    showFavoriteButton: false
                ),
                actions: .init(
                    onTapGesture: { [weak self] in
                        self?.selectPokemon(pokemon)
                    }
                )
            )
        }
    }
    
    func dismissPokemonDetailsModal() {
        route = nil
        pokemonDetailsViewModel = nil
    }
    
    func addToFavorite(_ data: PokemonData) {
        guard !favorites.contains(data) else { return }
        favorites.append(data)
    }
    
    func removeFromFavorites(_ data: PokemonData) {
        favorites.removeAll { $0.id == data.id }
    }
    
    func purgeFavorites() {
        favorites.removeAll()
    }
    
    // MARK: - Private API
    
    private func selectPokemon(_ pokemonData: PokemonData) {
        route = .pokemonDetails
        pokemonDetailsViewModel = .init(
            pokemonData: pokemonData
        )
        pokemonDetailsViewModel?.onDismiss = dismissPokemonDetailsModal
    }
}

struct TCAFavoritesScene: View {
    @StateObject var viewModel: TCAFavoritesViewModel
    
    var body: some View {
        NavigationView {
            contentView()
                .navigationTitle("Favorites")
                .sheet(
                    isPresented: .constant(viewModel.route == .pokemonDetails),
                    onDismiss: {
                        viewModel.dismissPokemonDetailsModal()
                    },
                    content: {
                        viewModel
                            .pokemonDetailsViewModel
                            .map { TCAPokemonDetailsScene(viewModel: $0) }
                    }
                )
        }
    }
    
    @ViewBuilder
    private func contentView() -> some View {
        if viewModel.cardViewModels.isEmpty {
            VStack {
                Spacer()
                Text("No favorites yet 😅")
                    .font(.largeTitle)
                Spacer()
            }
        } else {
            favoritesListView()
        }
    }
    
    @ViewBuilder
    private func favoritesListView() -> some View {
        List {
            ForEach(viewModel.cardViewModels) { cardViewModel in
                TCAPokemonCardView(viewModel: cardViewModel)
            }
        }
        .listRowInsets(
            EdgeInsets(
                top: 4,
                leading: 4,
                bottom: 4,
                trailing: 4
            )
        )
        .listStyle(.plain)
        .listRowSeparator(.hidden)
    }
}


#if DEBUG
struct TCAFavoritesScene_Previews: PreviewProvider {
    static var previews: some View {
        TCAFavoritesScene(viewModel: .init())
    }
}
#endif
