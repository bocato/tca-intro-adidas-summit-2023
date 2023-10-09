import Foundation

struct PokemonAPIResponse: Decodable {
    let results: [PokemonAPIItem]
}

struct PokemonAPIItem: Decodable {
    let name: String
    let url: String
}

struct PokemonDetailsAPIResponse: Decodable {
    let id: Int
    let name: String
    let species: PokemonSpecies
    let sprites: PokemonSprites
}

struct EvolutionChainResponse: Decodable {
    let chain: ChainLink
}

struct ChainLink: Decodable {
    let species: PokemonSpecies
    let evolvesTo: [ChainLink]
    
    enum CodingKeys: String, CodingKey {
        case species
        case evolvesTo = "evolves_to"
    }
}

struct PokemonSpecies: Decodable {
    let name: String
    let url: String
}


struct PokemonSprites: Decodable {
    let defaultURL: String
    
    enum CodingKeys: String, CodingKey {
        case defaultURL = "front_default"
    }
}

struct PokemonSpeciesResponse: Decodable {
    let evolutionChain: EvolutionChain
    
    enum CodingKeys: String, CodingKey {
        case evolutionChain = "evolution_chain"
    }
}

struct EvolutionChain: Decodable {
    let url: String
}

