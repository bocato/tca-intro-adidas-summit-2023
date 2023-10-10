import Combine

final class PokemonDetailsViewModel: ObservableObject {
    // MARK: - Dependencies
    
    let pokemonDataFetcher: PokemonDataFetching
    
    // MARK: - Properties
    
    let pokemonData: PokemonData
    var id: Int { pokemonData.id }
    enum ViewState: Equatable {
        case loadingEvolutions
        case loaded(evolutions: [String])
        case error(String)
    }
    @Published private(set) var viewState: ViewState = .loadingEvolutions
    var onDismiss: () -> Void = {}
        
    // MARK: - Intialization
    
    init(
        pokemonData: PokemonData,
        pokemonDataFetcher: PokemonDataFetching
    ) {
        self.pokemonData = pokemonData
        self.pokemonDataFetcher = pokemonDataFetcher
    }
    
    // MARK: - Public API
    
    @MainActor func loadEvolutions() async {
        viewState = .loadingEvolutions
        do {
            let evolutionsResponse = try await pokemonDataFetcher
                .fetchEvolutionsForPokemonURL(pokemonData.detailsURL)
            viewState = .loaded(
                evolutions: evolutionsResponse
            )
        } catch {
            viewState = .error("Could not load evolutions 😭")
        }
    }
}

import SwiftUI

struct PokemonDetailsScene: View {
    @StateObject var viewModel: PokemonDetailsViewModel
    
    var body: some View {
        NavigationView {
            contentView()
                .task { await viewModel.loadEvolutions() }
                .navigationTitle("Pokemon Details")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(
                            action: viewModel.onDismiss,
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
            HStack {
                Text("#\(String(format: "%03d", viewModel.pokemonData.id))")
                    .font(.headline)
                Text(viewModel.pokemonData.name)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            AsyncImage(url: URL(string: viewModel.pokemonData.imageURL)!) { phase in
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
        switch viewModel.viewState {
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

//#if DEBUG
//struct PokemonDetailsScene_Previews: PreviewProvider {
//    static var previews: some View {
//        let samplePokemon = PokemonData(number: 1, name: "Bulbasaur", details: "A grass/poison type Pokémon.", imageName: "bulbasaur")
//        return PokemonDetailsScene(viewModel: PokemonDetailsViewModel(pokemon: samplePokemon))
//    }
//}
//#endif
