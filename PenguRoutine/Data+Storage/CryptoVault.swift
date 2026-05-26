import Foundation
import CryptoKit

protocol GlacierVault {
    func stash(_ record: GlacierRecord)
    func stashFloes(url: String, mode: String)
    func markPrimed()
    func thaw() -> GlacierRecord
}

final class CryptoGlacierVault: GlacierVault {
    
    private let fm = FileManager.default
    private let dataDir: URL
    private let homeStore: UserDefaults
    private let suiteStore: UserDefaults
    private let cipherKey: SymmetricKey
    
    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.dataDir = docs.appendingPathComponent("PenguGlacier", isDirectory: true)
        if !fm.fileExists(atPath: dataDir.path) {
            try? fm.createDirectory(at: dataDir, withIntermediateDirectories: true)
        }
        self.homeStore = UserDefaults.standard
        self.suiteStore = UserDefaults(suiteName: GlacierConstants.suiteGlacier) ?? .standard
        let seed = (Bundle.main.bundleIdentifier ?? "pengu") + GlacierConstants.suiteGlacier
        let hash = SHA256.hash(data: Data(seed.utf8))
        self.cipherKey = SymmetricKey(data: Data(hash))
    }
    
    private var cipherURL: URL {
        dataDir.appendingPathComponent(GlacierConstants.cipherFile)
    }
    
    func stash(_ record: GlacierRecord) {
        let veiled = VeiledGlacier(
            chirps: veilDict(record.chirps),
            waddles: veilDict(record.waddles),
            floesURL: record.floesURL,
            floesMode: record.floesMode,
            untrodden: record.untrodden,
            consentChilled: record.consentChilled,
            consentThawed: record.consentThawed,
            consentMarkedAt: record.consentMarkedAt
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        
        do {
            let plaintext = try encoder.encode(veiled)
            let sealed = try AES.GCM.seal(plaintext, using: cipherKey)
            if let combined = sealed.combined {
                try combined.write(to: cipherURL, options: .atomic)
            }
        } catch {
        }
    }
    
    func stashFloes(url: String, mode: String) {
        suiteStore.set(url, forKey: GlacierKey.floesURL)
        homeStore.set(url, forKey: GlacierKey.floesURL)
        suiteStore.set(mode, forKey: GlacierKey.floesMode)
    }
    
    func markPrimed() {
        suiteStore.set(true, forKey: GlacierKey.primed)
        homeStore.set(true, forKey: GlacierKey.primed)
    }
    
    func thaw() -> GlacierRecord {
        guard fm.fileExists(atPath: cipherURL.path),
              let combined = try? Data(contentsOf: cipherURL) else {
            return fallback()
        }
        
        do {
            let sealed = try AES.GCM.SealedBox(combined: combined)
            let plaintext = try AES.GCM.open(sealed, using: cipherKey)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            
            let veiled = try decoder.decode(VeiledGlacier.self, from: plaintext)
            return GlacierRecord(
                chirps: unveilDict(veiled.chirps),
                waddles: unveilDict(veiled.waddles),
                floesURL: veiled.floesURL,
                floesMode: veiled.floesMode,
                untrodden: veiled.untrodden,
                consentChilled: veiled.consentChilled,
                consentThawed: veiled.consentThawed,
                consentMarkedAt: veiled.consentMarkedAt
            )
        } catch {
            return fallback()
        }
    }
    
    private func fallback() -> GlacierRecord {
        let floesURL = homeStore.string(forKey: GlacierKey.floesURL)
            ?? suiteStore.string(forKey: GlacierKey.floesURL)
        let floesMode = suiteStore.string(forKey: GlacierKey.floesMode)
        let primed = suiteStore.bool(forKey: GlacierKey.primed)
        
        return GlacierRecord(
            chirps: [:], waddles: [:],
            floesURL: floesURL, floesMode: floesMode,
            untrodden: !primed,
            consentChilled: false, consentThawed: false, consentMarkedAt: nil
        )
    }
    
    private func veilDict(_ dict: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (k, v) in dict { result[k] = veil(v) }
        return result
    }
    
    private func unveilDict(_ dict: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (k, v) in dict { result[k] = unveil(v) ?? v }
        return result
    }
    
    private func veil(_ input: String) -> String {
        let b64 = Data(input.utf8).base64EncodedString()
        return b64
            .replacingOccurrences(of: "+", with: "[")
            .replacingOccurrences(of: "/", with: "]")
    }
    
    private func unveil(_ input: String) -> String? {
        let b64 = input
            .replacingOccurrences(of: "[", with: "+")
            .replacingOccurrences(of: "]", with: "/")
        guard let data = Data(base64Encoded: b64),
              let text = String(data: data, encoding: .utf8) else { return nil }
        return text
    }
}

struct VeiledGlacier: Codable {
    let chirps: [String: String]
    let waddles: [String: String]
    let floesURL: String?
    let floesMode: String?
    let untrodden: Bool
    let consentChilled: Bool
    let consentThawed: Bool
    let consentMarkedAt: Date?
}
