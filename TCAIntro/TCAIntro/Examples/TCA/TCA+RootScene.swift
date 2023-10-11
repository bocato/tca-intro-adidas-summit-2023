import Foundation
import Combine
import ComposableArchitecture
import SwiftUI

 struct TCARoot: Reducer {
     // MARK: - State
     
     struct State: Equatable {
         var selectedTab: Int = 0
         var tabsState: Tabs.State = .init(
            listTab: .init(),
            favoritesTab: .init(favorites: [])
         )
         var numberOfFavorites: Int {
             tabsState.favoritesTab.favorites.count
         }
     }
     
     // MARK: - Action
     
     enum Action: Equatable {
         // Views
         case updateSelectedTab(Int)
         case resetFavoritesTapped
         // Internal
         case tabs(Tabs.Action)
     }
     
     // MARK: - Navigation
     
     struct Tabs: Reducer {
         struct State: Equatable {
             var listTab: TCAPokemonList.State
             var favoritesTab: TCAFavorites.State
         }
         enum Action: Equatable {
             case list(TCAPokemonList.Action)
             case favorites(TCAFavorites.Action)
         }
         
         var body: some Reducer<State, Action> {
             Scope(
                state: \.listTab,
                action: /Action.list
             ) { TCAPokemonList() }
             
             Scope(
                state: \.favoritesTab,
                action: /Action.favorites
             ) { TCAFavorites() }
         }
     }
     
     // MARK: - Dependencies
     
     var logger: LoggerProtocol = DefaultLogger()
     var pokemonDataFetcher: PokemonDataFetching = PokemonDataFetcher.shared
     
     // MARK: - Reducer Composition
     
     var body: some Reducer<State, Action> {
         Reduce(reduceCore(into:action:))
         Scope(
            state: \.tabsState,
            action: /Action.tabs,
            child: { Tabs() }
         )
     }
     
     // MARK: - Reducers
     
     func reduceCore(
         into state: inout State,
         action: Action
     ) -> Effect<Action> {
         switch action {
         case let .updateSelectedTab(index):
             state.selectedTab = index
             return .none
         case .resetFavoritesTapped:
             state.tabsState.favoritesTab.favorites.removeAll()
             for id in state.tabsState.listTab.pokemonCards.ids {
                 state.tabsState.listTab.pokemonCards[id: id]?.isFavorite = false
             }
             return .none
         case let .tabs(tabsAction):
             switch tabsAction {
             case let .list(listAction):
                 return reduce(
                    into: &state,
                    listAction: listAction
                 )
             case let .favorites(favoritesAction):
                 return reduce(
                    into: &state,
                    favoritesAction: favoritesAction
                 )
             }
         }
     }
     
     // MARK: - Child Reducers
     
     func reduce(
        into state: inout State,
        listAction action: TCAPokemonList.Action
     ) -> Effect<Action> {
         switch action {
         case let .pokemonCard(id, .delegate(.onFavoriteToggled(isFavorite))):
             if isFavorite {
                 guard
                    let card = state.tabsState.listTab.pokemonCards[id: id]
                 else { return .none }
                 state.tabsState.favoritesTab.favorites.append(card)
             } else {
                 state.tabsState.favoritesTab.favorites.remove(id: id)
                 state.tabsState.listTab.pokemonCards[id: id]?.isFavorite = false
             }
             return .none
         case .loadPokemons, .refreshData, .loadPokemonsResult, .navigateTo, .pokemonCard:
             return .none
         }
     }
     
     func reduce(
        into state: inout State,
        favoritesAction action: TCAFavorites.Action
     ) -> Effect<Action> {
         switch action {
         case let .pokemonCard(id, .delegate(.onFavoriteToggled(isFavorite))):
             if isFavorite {
                 guard
                    let card = state.tabsState.listTab.pokemonCards[id: id]
                 else { return .none }
                 state.tabsState.favoritesTab.favorites.append(card)
             } else {
                 state.tabsState.favoritesTab.favorites.remove(id: id)
                 state.tabsState.listTab.pokemonCards[id: id]?.isFavorite = false
             }
             return .none
         case .selectPokemon, .navigateTo, .pokemonCard:
             return .none
         }
     }
}

struct TCARootScene: View {
    let store: StoreOf<TCARoot>

    var body: some View {
        WithViewStore(store, observe: \.selectedTab) { viewStore in
            TabView(
                selection: viewStore.binding(
                    send: { .updateSelectedTab($0)}
                )
            )  {
                listTabView
                favoritesTabView
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset Favorites") {
                        store.send(.resetFavoritesTapped)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var listTabView: some View {
        TCAPokemonListScene(
            store: store.scope(
                state: \.tabsState.listTab,
                action: { .tabs(.list($0)) }
            )
        )
        .tabItem {
            Label("Pokemons", systemImage: "1.circle")
        }
        .tag(0)
    }
    
    @ViewBuilder
    private var favoritesTabView: some View {
        TCAFavoritesScene(
            store: store.scope(
                state: \.tabsState.favoritesTab,
                action: { .tabs(.favorites($0)) }
            )
        )
        .tabItem {
            Label {
                WithViewStore(store, observe: \.numberOfFavorites) { viewStore in
                    Text("Favorites (\(viewStore.state))")
                }
            } icon: {
                Image(systemName: "heart.fill")
            }
        }
        .tag(1)
    }
}
