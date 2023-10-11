import Foundation
import Combine
import ComposableArchitecture
import Dependencies
import SwiftUI

struct TCAPokemonList: Reducer {
    // MARK: - State
    
    struct State: Equatable {
        enum ViewState: Equatable {
            case loading
            case loaded
            case error(String)
        }
        var viewState: ViewState = .loading
        var pokemonCards: IdentifiedArrayOf<TCAPokemonCard.State> = .init()
        @PresentationState var navigation: Navigation.State?
    }
    
    // MARK: - Action
    
    enum Action: Equatable {
        // Views
        case loadPokemons
        case refreshData
        // Internal
        case loadPokemonsResult(TaskResult<[PokemonData]>)
        case pokemonCard(id: Int, action: TCAPokemonCard.Action)
        // Navigation
        case navigateTo(PresentationAction<Navigation.Action>)
    }
    
    // MARK: - Navigation
    
    struct Navigation: Reducer {
        enum State: Equatable {
            case pokemonDetails(TCAPokemonDetails.State)
        }
        enum Action: Equatable {
            case pokemonDetails(TCAPokemonDetails.Action)
        }
        
        var body: some Reducer<State, Action> {
            Scope(
                state: /State.pokemonDetails,
                action: /Action.pokemonDetails
            ) { TCAPokemonDetails() }
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.logger) var logger
    @Dependency(\.pokemonDataFetcher) var pokemonDataFetcher
    
    // MARK: - Reducer Composition
    
    var body: some Reducer<State, Action> {
        Reduce(reduceCore(into:action:))
            .ifLet(
                \.$navigation,
                 action: /Action.navigateTo,
                 destination: { Navigation() }
            )
            .forEach(
                \.pokemonCards,
                 action: /Action.pokemonCard,
                 element: { TCAPokemonCard() }
            )
    }
    
    // MARK: - Reducers
    
    func reduceCore(
        into state: inout State,
        action: Action
    ) -> Effect<Action> {
        switch action {
        // View
        case .loadPokemons:
            guard state.viewState != .loaded else { return .none }
            state.viewState = .loading
            return .run { send in
                await send(
                    .loadPokemonsResult(
                        TaskResult {
                            try await pokemonDataFetcher.fetchOriginalPokemons()
                        }
                    )
                )
            }
        case .refreshData:
            return .send(.loadPokemons)
        // Internal
        case let .loadPokemonsResult(.success(pokemons)):
            state.viewState = .loaded
            state.pokemonCards = .init(
                uniqueElements: pokemons.map { data in
                    TCAPokemonCard.State(
                        pokemonData: data
                    )
                }
            )
            return .none
        case let .loadPokemonsResult(.failure(error)):
            state.viewState = .error(error.localizedDescription)
            logger.logError(error)
            return .none
            
        case let .pokemonCard(id, .onContentTapped):
            guard
                let pokemonData = state.pokemonCards[id: id]?.pokemonData
            else { return .none }
            state.navigation = .pokemonDetails(
                .init(pokemonData: pokemonData)
            )
            return .none
        case .pokemonCard:
            return .none // we don't care about other actions...
        // Navigation
        case let .navigateTo(navigationAction):
            switch navigationAction {
            case .dismiss:
                return .none
            case let .presented(.pokemonDetails(action)):
                return reduce(
                    into: &state,
                    pokemonDetailsAction: action
                )
            }
        }
    }
    
    // MARK: - Child Reducers
    
    func reduce(
        into state: inout State,
        pokemonDetailsAction action: TCAPokemonDetails.Action
    ) -> Effect<Action> {
        guard // we only intercept delegated actions
            case let .delegate(delegateAction) = action
        else { return .none }
        switch delegateAction {
        case .closeButtonTapped:
            state.navigation = nil
            return .none
        }
    }
}

struct TCAPokemonListScene: View {
    let store: StoreOf<TCAPokemonList>
    
    var body: some View {
        NavigationView {
            contentView()
                .task { store.send(.loadPokemons) }
                .sheet(
                    store: store.scope(
                        state: \.$navigation,
                        action: { .navigateTo($0) }
                    ),
                    state: /TCAPokemonList.Navigation.State.pokemonDetails,
                    action: TCAPokemonList.Navigation.Action.pokemonDetails,
                    onDismiss: {},
                    content: { TCAPokemonDetailsScene(store: $0) }
                )
                .navigationTitle("Pokemons")
        }
    }
    
    @ViewBuilder
    private func contentView() -> some View {
        WithViewStore(store, observe: \.viewState) { viewStore in
            switch viewStore.state {
            case .loading:
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                
            case .loaded:
                List {
                    ForEachStore(
                        store.scope(
                            state: \.pokemonCards,
                            action: { .pokemonCard(id: $0, action: $1) }
                        ),
                        content: {
                            TCAPokemonCardView(store: $0)
                        }
                    )
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
                        viewStore.send(.refreshData)
                    }
                    Spacer()
                }
            }
        }
    }
}

#if DEBUG
struct TCAPokemonListScene_Previews: PreviewProvider {
    static var previews: some View {
        TCAPokemonListScene(
            store: .init(
                initialState: .init(
                    viewState: .loaded,
                    pokemonCards: makeMockCards()
                ),
                reducer: { EmptyReducer() }
            )
        )
        .previewDisplayName("Loaded List")
        
        TCAPokemonListScene(
            store: .init(
                initialState: .init(
                    viewState: .error("Some Error")
                ),
                reducer: { EmptyReducer() }
            )
        )
        .previewDisplayName("Error")
    }
}
#endif

import IdentifiedCollections

private func makeMockCards() -> IdentifiedArrayOf<[TCAPokemonCard.State]> {
    return .init(
        uniqueElements: PokemonData.mockList.map {
            TCAPokemonCard.State(pokemonData: $0)
        }
    )
}
