import Dependencies

// MARK: - PokemonDataFetcher
extension DependencyValues {
    enum PokemonDataFetcherKey: DependencyKey {
        typealias Value = PokemonDataFetching
        static var liveValue: PokemonDataFetching = PokemonDataFetcher()
        static var testValue: PokemonDataFetching = PokemonDataFetcherFailing()
    }
    
    var pokemonDataFetcher: PokemonDataFetching {
        get { self[PokemonDataFetcherKey.self] }
        set { self[PokemonDataFetcherKey.self] = newValue }
    }
}

// MARK: - Logger
extension DependencyValues {
    enum LoggerKey: DependencyKey {
        typealias Value = LoggerProtocol
        static var liveValue: LoggerProtocol = DefaultLogger()
    }
    
    var logger: LoggerProtocol {
        get { self[LoggerKey.self] }
        set { self[LoggerKey.self] = newValue }
    }
}
