import Foundation

struct PokemonData: Equatable {
    let id: Int
    let name: String
    let imageURL: String
    let detailsURL: String
}

enum PokemonDataFetchingError: Error {
    case invalidURL(String)
    case serverError(Error)
    case decodingError(DecodingError)
}

protocol PokemonDataFetching {
    func fetchOriginalPokemons() async throws -> [PokemonData]
    func fetchEvolutionsForPokemonURL(_ url: String) async throws -> [String]
}

final class PokemonDataFetcher: PokemonDataFetching {
    // MARK: Dependencies
    
    private let urlSession: URLSession
    private let jsonDecoder: JSONDecoder
    
    // MARK: - Singleton
    
    static let shared: PokemonDataFetcher = .init() // PokemonDataFetchingDummy()
    
    // MARK: - Properties
    
    private var pokemonDetailsCache: [String: PokemonDetailsAPIResponse] = [:]
    
    // MARK: - Initialization
    
    init(
        urlSession: URLSession,
        jsonDecoder: JSONDecoder
    ) {
        self.urlSession = urlSession
        self.jsonDecoder = jsonDecoder
    }
    
    convenience init() {
        self.init(
            urlSession: Self.makeDefaultSession(),
            jsonDecoder: .init()
        )
    }
    
    private static func makeDefaultSession() -> URLSession {
        let sessionConfiguration: URLSessionConfiguration = .default
        sessionConfiguration.urlCache = .shared
        let urlSession: URLSession = .init(
            configuration: sessionConfiguration
        )
        return urlSession
    }
    
    // MARK: - Public API

    func fetchOriginalPokemons() async throws -> [PokemonData] {
        let endpoint = "https://pokeapi.co/api/v2/pokemon?limit=25"//151"
        guard let url = URL(string: endpoint) else {
            throw PokemonDataFetchingError.invalidURL(endpoint)
        }
        
        do {
            let (data, _) = try await urlSession.data(from: url)
            let results = try jsonDecoder.decode(PokemonAPIResponse.self, from: data).results
            
            var detailedPokemons: [PokemonData] = []
            for item in results {
                let details = try await fetchPokemonDetails(from: item.url)
                let pokemon = PokemonData(
                    id: details.id,
                    name: details.name,
                    imageURL: details.sprites.defaultURL,
                    detailsURL: item.url
                )
                detailedPokemons.append(pokemon)
            }
            return detailedPokemons
        } catch let decodingError as DecodingError {
            throw PokemonDataFetchingError.decodingError(decodingError)
        } catch {
            throw PokemonDataFetchingError.serverError(error)
        }
    }
    
    func fetchEvolutionsForPokemonURL(_ url: String) async throws -> [String] {
        do {
            let details = try await fetchPokemonDetails(from: url)
            guard let speciesURL = URL(string: details.species.url) else {
                throw PokemonDataFetchingError.invalidURL(
                    details.species.url
                )
            }

            let (speciesData, _) = try await urlSession.data(from: speciesURL)
            let speciesResponse = try jsonDecoder.decode(PokemonSpeciesResponse.self, from: speciesData)
        
            guard
                let evolutionURL = URL(string: speciesResponse.evolutionChain.url)
            else {
                throw PokemonDataFetchingError.invalidURL(speciesResponse.evolutionChain.url)
            }
        
            let (evolutionData, _) = try await urlSession.data(from: evolutionURL)
            let evolutionResponse = try jsonDecoder.decode(EvolutionChainResponse.self, from: evolutionData)

            var evolutions: [String] = []
            var currentLink: ChainLink? = evolutionResponse.chain
            while let link = currentLink {
                evolutions.append(link.species.name)
                currentLink = link.evolvesTo.first
            }

            return evolutions
        } catch let decodingError as DecodingError {
            throw PokemonDataFetchingError.decodingError(decodingError)
        } catch {
            throw PokemonDataFetchingError.serverError(error)
        }
    }
    
    // MARK: - Private API
    
    private func fetchPokemonDetails(from url: String) async throws -> PokemonDetailsAPIResponse {
        guard let detailsURL = URL(string: url) else {
            throw PokemonDataFetchingError.invalidURL(url)
        }
        
        if let cachedData = pokemonDetailsCache[url] {
            return cachedData
        }
        
        do {
            let (data, _) = try await urlSession.data(from: detailsURL)
            let decodedResponse = try jsonDecoder.decode(PokemonDetailsAPIResponse.self, from: data)
            pokemonDetailsCache[url] = decodedResponse
            return decodedResponse
        } catch let decodingError as DecodingError {
            throw PokemonDataFetchingError.decodingError(decodingError)
        } catch {
            throw PokemonDataFetchingError.serverError(error)
        }
    }
}


extension URL {
    static func unwrapped(_ string: String) -> URL {
        guard let url = URL(string: string) else {
            fatalError("Invalid URL!")
        }
        return url
    }
}

#if DEBUG
extension PokemonData {
    static func fixture(
        id: Int = 1,
        name: String = "Pikachu",
        imageURL: String = "www.google.com/logo.png",
        detailsURL: String = "www.google.com"
    ) -> Self {
        .init(
            id: id,
            name: name,
            imageURL: imageURL,
            detailsURL: detailsURL
        )
    }
}

struct PokemonDataFetchingDummy: PokemonDataFetching {
    func fetchOriginalPokemons() async throws -> [PokemonData] {
        [
            .fixture(id: 1),
            .fixture(id: 2),
            .fixture(id: 3)
        ]
    }
    
    func fetchEvolutionsForPokemonURL(_ url: String) async throws -> [String] {
        [
            "Evolution 1",
            "Evolution 2",
            "Evolution 3"
        ]
    }
}
#endif
