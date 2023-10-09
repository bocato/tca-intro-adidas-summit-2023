import Combine
import ComposableArchitecture

struct TCAPokemonDetails: Reducer {
    // MARK: - State
    
    struct State: Equatable {
        let pokemonData: PokemonData
        
        enum ViewState: Equatable {
            case loadingEvolutions
            case loaded(evolutions: [String])
            case error(String)
        }
        var viewState: ViewState = .loadingEvolutions
    }
    
    // MARK: - Action
    
    enum Action: Equatable {
        // View
        case loadEvolutions
        case closeButtonTapped
        // Internal
        case evolutionsResult(TaskResult<[String]>)
        // Delegate
        case delegate(DelegateAction)
        enum DelegateAction: Equatable {
            case closeButtonTapped
        }
    }
    
    // MARK: - Dependencies
    
    var pokemonDataFetcher: PokemonDataFetching = PokemonDataFetcher.shared
    
    // MARK: - Reducer
    
    func reduce(
        into state: inout State,
        action: Action
    ) -> Effect<Action> {
        switch action {
        // View
        case .loadEvolutions:
            state.viewState = .loadingEvolutions
            let detailsURL = state.pokemonData.detailsURL
            return .run { send in
                await send(
                    .evolutionsResult(
                        TaskResult {
                            try await pokemonDataFetcher
                                .fetchEvolutionsForPokemonURL(detailsURL)
                        }
                    )
                )
            }
        case .closeButtonTapped:
            return .send(.delegate(.closeButtonTapped))
            
        // Internal
        case let .evolutionsResult(.success(evolutions)):
            state.viewState = .loaded(
                evolutions: evolutions
            )
            return .none
            
        case .evolutionsResult(.failure):
            state.viewState = .error("Could not load evolutions 😭")
            return .none
        // Delegate
        case .delegate:
            return .none // those are handled on parent
        }
    }
}

import SwiftUI

struct TCAPokemonDetailsScene: View {
    let store: StoreOf<TCAPokemonDetails>
    
    var body: some View {
        NavigationView {
            contentView()
                .task { store.send(.loadEvolutions) }
                .navigationTitle("Pokemon Details")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(
                            action: {
                                store.send(.closeButtonTapped)
                            },
                            label: {
                                Image(systemName: "multiply")
                                    .foregroundColor(.accentColor)
                            }
                        )
                    }
                }
        }
    }
    
    @ViewBuilder
    private func contentView() -> some View {
        VStack {
            pokemonInfoView()
            evolutionsList()
            Spacer()
        }
        .padding()
    }
    
    @ViewBuilder
    private func pokemonInfoView() -> some View {
        VStack {
            WithViewStore(store, observe: \.pokemonData) { viewStore in
                HStack {
                    Text("#\(String(format: "%03d", viewStore.id))")
                        .font(.headline)
                    Text(viewStore.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
            }
        }
    }
    
    @ViewBuilder
    private func pokemonImageView(for url: URL) -> some View {
        WithViewStore(store, observe: \.viewState) { viewStore in
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image.resizable()
                        .scaledToFit()
                case .failure:
                    Image(systemName: "xmark.circle")
                @unknown default:
                    EmptyView()
                }
            }
        }
    }
    
    @ViewBuilder
    private func evolutionsList() -> some View {
        WithViewStore(store, observe: \.viewState) { viewStore in
            switch viewStore.state {
            case .loadingEvolutions:
                ProgressView()
            case let .loaded(evolutions):
                VStack(alignment: .center) {
                    Text("Evolutions (\(evolutions.count))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    List {
                        ForEach(evolutions, id: \.self) { evolution in
                            Text(evolution)
                                .font(.title3)
                        }
                    }
                }
            case let .error(message):
                Text(message)
                    .foregroundColor(.red)
            }
        }
    }
}

//#if DEBUG
//struct PokemonDetailsScene_Previews: PreviewProvider {
//    static var previews: some View {
//        let samplePokemon = PokemonData(number: 1, name: "Bulbasaur", details: "A grass/poison type Pokémon.", imageName: "bulbasaur")
//        return PokemonDetailsScene(viewModel: PokemonDetailsViewModel(pokemon: samplePokemon))
//    }
//}
//#endif
