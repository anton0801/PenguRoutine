import Foundation

protocol VoltageSentinel {
    func sentinelWatch() async throws -> Bool
}

protocol AttributionPing {
    func ping(deviceID: String) async throws -> [String: Any]
}

protocol FloesScout {
    func scout(seed: [String: Any]) async throws -> String
}

protocol ConsentChirper {
    func chirp() async -> Bool
    func armPushSignal()
}



final class SupabaseVoltageSentinel: VoltageSentinel {
    
    func sentinelWatch() async throws -> Bool {
        return true
    }
}
