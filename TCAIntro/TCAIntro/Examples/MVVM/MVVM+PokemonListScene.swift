import Foundation
import Combine
import SwiftUI

final class PokemonListViewModel: ObservableObject {
    // MARK: - Dependencies
    
    let pokemonDataFetcher: PokemonDataFetching
    let logger: LoggerProtocol
    
    // MARK: - Properties
    
    enum ViewState: Equatable {
        case loading
        case loaded
        case error(String)
    }
    @Published private(set) var viewState: ViewState = .loading
    @Published private(set) var cardViewModels: [PokemonCardViewModel] = [] {
        didSet { bindCardViewModels() }
    }
    
    enum Route: Equatable {
        case pokemonDetails
    }
    @Published private(set) var route: Route?
    
    private var subscriptions: Set<AnyCancellable> = .init()
    
    struct Actions {
        let onFavoriteStateChanged: (PokemonData, Bool) -> Void
    }
    var actions: Actions?
    
    // MARK: - Child Flows
    
    @Published private(set) var pokemonDetailsViewModel: PokemonDetailsViewModel?
    
    
    // MARK: - Intialization

    init(
        pokemonDataFetcher: PokemonDataFetching,
        logger: LoggerProtocol
    ) {
        self.pokemonDataFetcher = pokemonDataFetcher
        self.logger = logger
    }
    
    // MARK: - Binding
    
    private func bindCardViewModels() {
        guard !cardViewModels.isEmpty else { return }
        cardViewModels.forEach { cardViewModel in
            cardViewModel
                .$evolutionsRequestError
                .sink { [logger] error in
                    guard let error else { return }
                    logger.logError(error)
                }
                .store(in: &subscriptions)
            
            cardViewModel
                .$isFavorite
                .removeDuplicates()
                .sink { [weak self] isFavorite in
                    self?.actions?.onFavoriteStateChanged(
                        cardViewModel.pokemonData,
                        isFavorite
                    )
                }
                .store(in: &subscriptions)
        }
    }
    
    // MARK: - Public API
    
    @MainActor func loadPokemons() async {
        guard viewState != .loaded else { return }
        viewState = .loading
        cardViewModels = []
        do {
            let results = try await pokemonDataFetcher.fetchOriginalPokemons()
            cardViewModels = results.map { [pokemonDataFetcher] pokemonData in
                let cardViewModel = PokemonCardViewModel(
                    pokemonData: pokemonData,
                    actions: .init(
                        onTapGesture: { [weak self] in
                            self?.selectPokemon(pokemonData)
                        }
                    ),
                    pokemonDataFetcher: pokemonDataFetcher
                )
                return cardViewModel
            }
            viewState = .loaded
        } catch {
            viewState = .error(error.localizedDescription)
            logger.logError(error)
        }
    }
    
    @MainActor func refreshData() async {
        await loadPokemons()
    }
    
    func dismissPokemonDetailsModal() {
        route = nil
        pokemonDetailsViewModel = nil
    }
    
    // MARK: - Private
    
    private func selectPokemon(_ pokemonData: PokemonData) {
        route = .pokemonDetails
        pokemonDetailsViewModel = .init(
            pokemonData: pokemonData,
            pokemonDataFetcher: pokemonDataFetcher
        )
        pokemonDetailsViewModel?.onDismiss = dismissPokemonDetailsModal
    }
}

struct PokemonListScene: View {
    @StateObject var viewModel: PokemonListViewModel
    
    var body: some View {
        NavigationView {
            contentView()
                .task { await viewModel.loadPokemons() }
                .navigationTitle("Pokemons")
                .sheet(
                    isPresented: .constant(viewModel.route == .pokemonDetails),
                    onDismiss: {
                        viewModel.dismissPokemonDetailsModal()
                    },
                    content: {
                        viewModel
                            .pokemonDetailsViewModel
                            .map { PokemonDetailsScene(viewModel: $0) }
                    }
                )
        }
    }
    
    @ViewBuilder
    private func contentView() -> some View {
        switch viewModel.viewState {
        case .loading:
            VStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            
        case .loaded:
            List {
                ForEach(viewModel.cardViewModels) { cardViewModel in
                    PokemonCardView(viewModel: cardViewModel)
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
            
        case let .error(message):
            VStack {
                Spacer()
                Text(message)
                    .foregroundColor(.red)
                Button("Retry") {
                    Task { await viewModel.refreshData() }
                }
                Spacer()
            }
        }
    }
}

#if DEBUG
struct PokemonListScene_Previews: PreviewProvider {
    static var previews: some View {
        PokemonListScene(
            viewModel: .init(
                pokemonDataFetcher: PokemonDataFetchingMock(),
                logger: DummyLogger()
            )
        )
        .previewDisplayName("Loaded List")
        
        PokemonListScene(
            viewModel: .init(
                pokemonDataFetcher: PokemonDataFetchingMock(fails: true),
                logger: DummyLogger()
            )
        )
        .previewDisplayName("Error")
    }
}
#endif
