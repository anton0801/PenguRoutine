import Foundation

final class Atomic<Value> {
    
    private var _value: Value
    private let queue: DispatchQueue
    
    init(_ initial: Value, label: String = "com.pengu.routine.atomic") {
        self._value = initial
        self.queue = DispatchQueue(label: label)
    }
    
    var value: Value {
        queue.sync { _value }
    }
    
    func mutate(_ block: (inout Value) -> Void) {
        queue.sync { block(&_value) }
    }
    
    func replace(_ new: Value) {
        queue.sync { _value = new }
    }
    
    func read<R>(_ block: (Value) -> R) -> R {
        queue.sync { block(_value) }
    }
}

struct GlacierSnapshot {
    var chirps: [String: String] = [:]
    var waddles: [String: String] = [:]
    var floesURL: String? = nil
    var floesMode: String? = nil
    var chirpsReady: Bool { !chirps.isEmpty }
    var untrodden: Bool = true
    var camped: Bool = false
    var slipperyDone: Bool = false
    var organicFloe: Bool { chirps["af_status"] == "Organic" }
    var consentChilled: Bool = false
    var consentThawed: Bool = false
    var consentMarkedAt: Date? = nil
    
    var consentRipe: Bool {
        guard !consentChilled && !consentThawed else { return false }
        if let date = consentMarkedAt {
            let elapsed = Date().timeIntervalSince(date) / 86400
            return elapsed >= 3
        }
        return true
    }
    
    static func hydrate(from record: GlacierRecord) -> GlacierSnapshot {
        var snap = GlacierSnapshot()
        snap.chirps = record.chirps
        snap.waddles = record.waddles
        snap.floesURL = record.floesURL
        snap.floesMode = record.floesMode
        snap.untrodden = record.untrodden
        snap.consentChilled = record.consentChilled
        snap.consentThawed = record.consentThawed
        snap.consentMarkedAt = record.consentMarkedAt
        return snap
    }
    
    func freeze() -> GlacierRecord {
        GlacierRecord(
            chirps: chirps, waddles: waddles,
            floesURL: floesURL, floesMode: floesMode,
            untrodden: untrodden,
            consentChilled: consentChilled, consentThawed: consentThawed,
            consentMarkedAt: consentMarkedAt
        )
    }
}
