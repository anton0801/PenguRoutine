import Foundation

final class AppsFlyerAttributionPing: AttributionPing {
    
    private let session: URLSession
    
    func ping(deviceID: String) async throws -> [String: Any] {
        var components = URLComponents(string: "https://gcdsdk.appsflyer.com/install_data/v4.0/id\(GlacierConstants.appCode)")
        components?.queryItems = [
            URLQueryItem(name: "devkey", value: GlacierConstants.trackerKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]
        
        guard let url = components?.url else {
            throw RoutineFault.packetCracked(stage: "URL build")
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw RoutineFault.wireFrozen(attempts: 0)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw RoutineFault.packetCracked(stage: "attribution JSON")
        }
        
        return json
    }
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
}
