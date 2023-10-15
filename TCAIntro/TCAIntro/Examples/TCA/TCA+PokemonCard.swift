import Foundation
import Combine
import ComposableArchitecture
import Dependencies
import SwiftUI

struct TCAPokemonCard: Reducer {
    // MARK: - State
    
    struct State: Equatable, Identifiable {
        let pokemonData: PokemonData
        var isFavorite: Bool = false
        var isLoadingEvolutions: Bool = false
        var evolutions: [String]?
        var evolutionsRequestError: NSError?
        
        // Identifiable
        var id: Int { pokemonData.id }
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
    
    @Dependency(\.pokemonDataFetcher) var pokemonDataFetcher
    
    // MARK: - Reducer
    
    func reduce(
        into state: inout State,
        action: Action
    ) -> Effect<Action> {
        switch action {
        // View
        case .loadEvolutionsTapped:
            let detailsURL = state.pokemonData.detailsURL
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
            state.isFavorite.toggle()
            return .send(
                .delegate(
                    .onFavoriteToggled(
                        state.isFavorite
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
        VStack {
            ZStack {
                favoriteButton()
                pokemonInfoView()
            }
            evolutionsListView()
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .shadow(radius: 5)
    }
    
    @ViewBuilder
    private func favoriteButton() -> some View {
        WithViewStore(store, observe: \.isFavorite) { viewStore in
            HStack(alignment: .top) {
                Spacer()
                Button(
                    action: { viewStore.send(.onFavoriteTapped) },
                    label: {
                        let favoriteIcon = viewStore.state ? "heart.fill" : "heart"
                        let iconColor: Color = viewStore.state ? .red : .gray
                        Image(systemName: favoriteIcon)
                            .foregroundColor(iconColor)
                    }
                )
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func pokemonInfoView() -> some View {
        WithViewStore(store, observe: \.pokemonData) { viewStore in
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
        WithViewStore(
            store, observe: {
                (
                    evolutions: $0.evolutions,
                    isLoadingEvolutions: $0.isLoadingEvolutions
                )
            },
            removeDuplicates: ==
        ) { viewStore in
            VStack {
                if let evolutions = viewStore.evolutions {
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
                    Button(
                        action: {
                            viewStore.send(.loadEvolutionsTapped)
                        },
                        label: {
                            if viewStore.isLoadingEvolutions {
                                ProgressView()
                            } else {
                                Text("Load Evolutions")
                            }
                        }
                    )
                    .buttonStyle(.borderless)
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
