import Foundation
import Combine
import ComposableArchitecture
import Dependencies
import SwiftUI

struct TCAFavorites: Reducer {
    struct State: Equatable {
        var favorites: IdentifiedArrayOf<TCAPokemonCard.State>
        @PresentationState var navigation: Navigation.State?
    }
    
    enum Action: Equatable {
        // Views
        case selectPokemon(PokemonData)
        // Internal
        case pokemonCard(id: Int, action: TCAPokemonCard.Action)
        case navigateTo(PresentationAction<Navigation.Action>)
    }
    
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
    
    // MARK: - Reducer Composition
    
    var body: some Reducer<State, Action> {
        Reduce(reduceCore(into:action:))
            .ifLet(
                \.$navigation,
                 action: /Action.navigateTo,
                 destination: { Navigation() }
            )
            .forEach(
                \.favorites,
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
        case let .selectPokemon(selectedPokemon):
            state.navigation = .pokemonDetails(
                .init(pokemonData: selectedPokemon)
            )
            return .none
        // Internal
        case let .pokemonCard(id, .onContentTapped):
            guard
                let pokemonData = state.favorites[id: id]?.pokemonData
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
                return reducePokemonDetails(
                    into: &state,
                    action: action
                )
            }
        }
    }
    
    // MARK: - Child Reducers
    
    func reducePokemonDetails(
        into state: inout State,
        action pokemonDetailsAction: TCAPokemonDetails.Action
    ) -> Effect<Action> {
        guard // we only intercept delegated actions
            case let .delegate(delegateAction) = pokemonDetailsAction
        else { return .none }
        switch delegateAction {
        case .closeButtonTapped:
            state.navigation = nil
            return .none
        }
    }
}

struct TCAFavoritesScene: View {
    let store: StoreOf<TCAFavorites>
        
    var body: some View {
        NavigationView {
            contentView()
                .navigationTitle("Favorites")
                .sheet(
                    store: store.scope(
                        state: \.$navigation,
                        action: { .navigateTo($0) }
                    ),
                    state: /TCAFavorites.Navigation.State.pokemonDetails,
                    action: TCAFavorites.Navigation.Action.pokemonDetails,
                    content: { TCAPokemonDetailsScene(store: $0) }
                )
        }
    }

    @ViewBuilder
    private func contentView() -> some View {
        WithViewStore(store, observe: \.favorites.count) { viewStore in
            if viewStore.state > 0 {
                favoritesListView()
            } else {
                VStack {
                    Spacer()
                    Text("No favorites yet 😅")
                        .font(.largeTitle)
                    Spacer()
                }
            }
        }
    }
    
    @ViewBuilder
    private func favoritesListView() -> some View {
        List {
            ForEachStore(
                store.scope(
                    state: \.favorites,
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
    }
}
