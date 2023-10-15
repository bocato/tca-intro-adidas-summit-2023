import Foundation
import OSLog

protocol LoggerProtocol {
    func logError(_ error: Error)
}

struct DefaultLogger: LoggerProtocol {
    var logger: Logger = .init(
        subsystem: "TCAIntro",
        category: "Log"
    )
    
    func logError(_ error: Error) {
        #if DEBUG
        let message = error.localizedDescription
        logger.error("\(message)")
        #endif
    }
}

#if DEBUG
struct DummyLogger: LoggerProtocol {
    func logError(_ error: Error) {}
}
#endif
