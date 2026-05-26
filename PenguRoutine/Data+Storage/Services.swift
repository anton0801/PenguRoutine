import Foundation
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit
import UIKit
import UserNotifications

extension UNUserNotificationCenter {
    func requestAuthorizationAsync(options: UNAuthorizationOptions) async -> Bool {
        await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            self.requestAuthorization(options: options) { granted, error in
                if let error = error {
                    print("\(GlacierConstants.logFlipper) Notification auth error: \(error)")
                }
                continuation.resume(returning: granted)
            }
        }
    }
}

final class HTTPFloesScout: FloesScout {
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    private let pauseLadder: [Double] = [88.0, 176.0, 352.0]
    
    private var browserAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    func scout(seed: [String: Any]) async throws -> String {
        guard let endpoint = URL(string: GlacierConstants.backendIceberg) else {
            throw RoutineFault.packetCracked(stage: "endpoint URL")
        }
        
        var body: [String: Any] = seed
        body["os"] = "iOS"
        body["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        body["store_id"] = "id\(GlacierConstants.appCode)"
        body["push_token"] = UserDefaults.standard.string(forKey: GlacierKey.push)
            ?? Messaging.messaging().fcmToken
        body["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(browserAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        var lastFault: Error?
        var attempts = 0
        
        for (idx, pause) in pauseLadder.enumerated() {
            attempts += 1
            do {
                return try await singleShot(request)
            } catch let fault as RoutineFault {
                if case .floesDenied = fault {
                    throw fault
                }
                if case .currentClogged(let retryAfter) = fault {
                    try await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
                    continue
                }
                lastFault = fault
                if idx < pauseLadder.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(pause * 1_000_000_000))
                }
            } catch {
                lastFault = error
                if idx < pauseLadder.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(pause * 1_000_000_000))
                }
            }
        }
        
        if let lastFault = lastFault {
            throw lastFault
        }
        throw RoutineFault.wireFrozen(attempts: attempts)
    }
    
    private func singleShot(_ request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw RoutineFault.wireFrozen(attempts: 0)
        }
        
        if http.statusCode == 404 {
            throw RoutineFault.floesDenied(httpCode: 404)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw RoutineFault.packetCracked(stage: "JSON parse")
        }
        
        guard let ok = json["ok"] as? Bool else {
            throw RoutineFault.packetCracked(stage: "missing 'ok'")
        }
        
        if !ok {
            throw RoutineFault.floesDenied(httpCode: 200)
        }
        
        guard let url = json["url"] as? String, !url.isEmpty else {
            throw RoutineFault.packetCracked(stage: "missing or empty 'url'")
        }
        
        return url
    }
}


final class ServiceContainer {
    lazy var vault: GlacierVault = CryptoGlacierVault()
    lazy var sentinel: VoltageSentinel = SupabaseVoltageSentinel()
    lazy var attribution: AttributionPing = AppsFlyerAttributionPing()
    lazy var scout: FloesScout = HTTPFloesScout()
    lazy var chirper: ConsentChirper = NotificationConsentChirper()
}
