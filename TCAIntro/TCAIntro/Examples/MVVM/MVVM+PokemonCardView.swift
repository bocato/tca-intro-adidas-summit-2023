import Foundation
import Combine
import SwiftUI

final class PokemonCardViewModel: ObservableObject, Identifiable {
    // MARK: - Dependencies
    
    var pokemonDataFetcher: PokemonDataFetching =  PokemonDataFetcher.shared
    
    // MARK: - Properties
    
    let pokemonData: PokemonData
    struct Configs {
        var loadEvolutionsEnabled: Bool = true
        var showFavoriteButton: Bool = true
    }
    let configs: Configs
    struct Actions {
        var onTapGesture: () -> Void = {}
    }
    private let actions: Actions
    
    @Published var isFavorite: Bool = false
    @Published private(set) var isLoadingEvolutions: Bool = false
    @Published private(set) var evolutions: [String]?
    @Published private(set) var evolutionsRequestError: Error?
    
    // MARK: - Other Properties
    
    var id: Int { pokemonData.id }
    
    // MARK: - Intialization
    
    init(
        pokemonData: PokemonData,
        configs: Configs = .init(),
        actions: Actions
    ) {
        self.pokemonData = pokemonData
        self.configs = configs
        self.actions = actions
    }
    
    // MARK: - Public API
    
    @MainActor func loadEvolutions() async {
        guard evolutions == nil else { return }
        
        evolutionsRequestError = nil
        isLoadingEvolutions = true
        defer { isLoadingEvolutions = false }
        
        do {
            let evolutionsResponse = try await pokemonDataFetcher
                .fetchEvolutionsForPokemonURL(pokemonData.detailsURL)
            evolutions = evolutionsResponse
        } catch {
            evolutionsRequestError = error
        }
    }
    
    func toggleFavorite() {
        isFavorite.toggle()
    }
    
    func onCardContentTapped() {
        actions.onTapGesture()
    }
}

struct PokemonCardView: View {
    @StateObject var viewModel: PokemonCardViewModel
    
    var body: some View {
        VStack {
            ZStack {
                if viewModel.configs.showFavoriteButton {
                    favoriteButton()
                        .padding(.horizontal)
                }
                pokemonInfoView()
                    .onTapGesture { viewModel.onCardContentTapped()
                    }
            }
            if viewModel.configs.loadEvolutionsEnabled {
                evolutionsListView()
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .shadow(radius: 5)
    }
    
    @ViewBuilder
    private func favoriteButton() -> some View {
        HStack(alignment: .top) {
            Spacer()
            Button(
                action: {
                    viewModel.toggleFavorite()
                },
                label: {
                    let favoriteIcon = viewModel.isFavorite ? "heart.fill" : "heart"
                    let iconColor: Color = viewModel.isFavorite ? .red : .gray
                    Image(systemName: favoriteIcon)
                        .foregroundColor(iconColor)
                }
            )
        }
    }
    
    @ViewBuilder
    private func pokemonInfoView() -> some View {
        HStack {
            AsyncImage(url: .unwrapped(viewModel.pokemonData.imageURL)) { phase in
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
                Text("#\(String(format: "%03d", viewModel.pokemonData.id))")
                    .font(.headline)
                Text(viewModel.pokemonData.name.capitalized)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            Spacer()
        }
        .scaledToFill()
    }
    
    @ViewBuilder
    private func evolutionsListView() -> some View {
        VStack {
            if let evolutions = viewModel.evolutions {
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
                    Task { await viewModel.loadEvolutions() }
                }
                .buttonStyle(.borderless)
            }
        }
    }
}

#if DEBUG
struct PokemonCardViewModel_Previews: PreviewProvider {
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
