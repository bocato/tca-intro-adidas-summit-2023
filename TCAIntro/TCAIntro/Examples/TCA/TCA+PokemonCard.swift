import Foundation
import Combine
import ComposableArchitecture
import SwiftUI

struct TCAPokemonCard: Reducer {
    // MARK: - State
    
    struct State: Equatable, Identifiable {
        struct Props: Equatable {
            let pokemonData: PokemonData
            private(set) var loadEvolutionsEnabled: Bool = true
            private(set) var showFavoriteButton: Bool = true
        }
        let props: Props
        var favoritedButtonState: FavoriteButton
        var isLoadingEvolutions: Bool = false
        var evolutions: [String]?
        var evolutionsRequestError: NSError?
        
        // Support for scoping states
        struct FavoriteButton: Equatable {
            let isVisible: Bool
            var isFavorite: Bool = false
        }
        // Identifiable
        var id: Int { props.pokemonData.id }
    }
    
    // MARK: - Action
    
    enum Action: Equatable {
        // View
        case loadEvolutionsTapped
        case onContentTapped
        case onFavoriteTapped
        // Internal
        case evolutionsResult(TaskResult<[String]>)
        // Delegate
        case delegate(DelegateAction)
        enum DelegateAction: Equatable {
            case onContentTap
            case onFavoriteToggled(Bool)
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
        case .loadEvolutionsTapped:
            let detailsURL = state.props.pokemonData.detailsURL
            state.evolutionsRequestError = nil
            state.isLoadingEvolutions = true
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
        case .onContentTapped:
            return .send(.delegate(.onContentTap))
            
        case .onFavoriteTapped:
            state.favoritedButtonState.isFavorite.toggle()
            return .send(
                .delegate(
                    .onFavoriteToggled(
                        state.favoritedButtonState.isFavorite
                    )
                )
            )
            
        // Internal
        case let .evolutionsResult(.success(evolutions)):
            state.isLoadingEvolutions = false
            state.evolutions = evolutions
            return .none
            
        case let .evolutionsResult(.failure(error)):
            state.isLoadingEvolutions = false
            state.evolutionsRequestError = error as NSError
            return .none
        // Delegate
        case .delegate:
            return .none // We handle this in the parent 👴
        }
    }
}

struct TCAPokemonCardView: View {
    let store: StoreOf<TCAPokemonCard>
    
    var body: some View {
        WithViewStore(store, observe: \.props.loadEvolutionsEnabled) { viewStore in
            VStack {
                ZStack {
                    favoriteButton()
                    pokemonInfoView()
                }
                if viewStore.state {
                    evolutionsListView()
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .shadow(radius: 5)
        }
    }
    
    @ViewBuilder
    private func favoriteButton() -> some View {
        WithViewStore(store, observe: \.favoritedButtonState) { viewStore in
            HStack(alignment: .top) {
                Spacer()
                Button(
                    action: { viewStore.send(.onFavoriteTapped) },
                    label: {
                        let favoriteIcon = viewStore.isFavorite ? "heart.fill" : "heart"
                        let iconColor: Color = viewStore.isFavorite ? .red : .gray
                        Image(systemName: favoriteIcon)
                            .foregroundColor(iconColor)
                    }
                )
            }
            .opacity(viewStore.isVisible ? 1 : 0)
            .disabled(viewStore.isVisible == false)
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func pokemonInfoView() -> some View {
        WithViewStore(store, observe: \.props.pokemonData) { viewStore in
            HStack {
                AsyncImage(url: .unwrapped(viewStore.imageURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case let .success(image):
                        image.resizable().frame(width: 64, height: 64)
                    case .failure:
                        Image(systemName: "xmark.circle")
                    @unknown default:
                        EmptyView()
                    }
                }
                HStack {
                    Text("#\(String(format: "%03d", viewStore.id))")
                        .font(.headline)
                    Text(viewStore.name.capitalized)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                Spacer()
            }
            .scaledToFill()
            .onTapGesture {
                viewStore.send(.onContentTapped)
            }
        }
    }
    
    @ViewBuilder
    private func evolutionsListView() -> some View {
        WithViewStore(store, observe: \.evolutions) { viewStore in
            VStack {
                if let evolutions = viewStore.state {
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
                    .scaledToFit()
                } else {
                    Button("Load Evolutions") {
                        viewStore.send(.loadEvolutionsTapped)
                    }.buttonStyle(.borderless)
                }
            }
        }
    }
}

#if DEBUG
struct TCAPokemonCardViewModel_Previews: PreviewProvider {
    static var previews: some View {
        PokemonCardView(
            viewModel: .init(
                pokemonData: .init(
                    id: 1,
                    name: "name",
                    imageURL: "imageURL",
                    detailsURL: "detailsURL"
                ),
                actions: .init(
                    onTapGesture: {}
                )
            )
        )
    }
}
#endif
