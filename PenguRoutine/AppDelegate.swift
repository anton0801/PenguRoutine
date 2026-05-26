import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private let mediator = FlockMediator()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        mediator.registerChirpHerald(ChirpHerald())
        mediator.registerWaddleScout(WaddleScout())
        mediator.registerPushTracker(PushTracker())
        mediator.registerTokenKeeper(TokenKeeper())
        
        mediator.kickstartBoot(
            messagingDelegate: self,
            notificationDelegate: self,
            appsFlyerDelegate: self,
            deepLinkDelegate: self
        )

        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            mediator.notify(.pushArrived(remote))
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    @objc private func onActivation() {
        mediator.kickActivation()
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { [weak self] token, err in
            guard err == nil, let t = token else { return }
            self?.mediator.notify(.tokenIssued(t))
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        mediator.notify(.pushArrived(notification.request.content.userInfo))
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        mediator.notify(.pushArrived(response.notification.request.content.userInfo))
        completionHandler()
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        mediator.notify(.pushArrived(userInfo))
        completionHandler(.newData)
    }
}

extension AppDelegate: AppsFlyerLibDelegate, DeepLinkDelegate {
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        mediator.notify(.attributionReady(data))
    }
    
    func onConversionDataFail(_ error: Error) {
        mediator.notify(.attributionReady([
            "error": true,
            "error_desc": error.localizedDescription
        ]))
    }
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status, let link = result.deepLink else { return }
        mediator.notify(.deeplinkResolved(link.clickEvent))
    }
}

enum MediatorEvent {
    case attributionReady([AnyHashable: Any])
    case deeplinkResolved([AnyHashable: Any])
    case pushArrived([AnyHashable: Any])
    case tokenIssued(String)
}

protocol FlockSubordinate: AnyObject {
    var mediator: FlockMediator? { get set }
    func receive(_ event: MediatorEvent)
}

final class FlockMediator {
    
    private var chirpHerald: ChirpHerald?
    private var waddleScout: WaddleScout?
    private var pushTracker: PushTracker?
    private var tokenKeeper: TokenKeeper?
    
    func registerChirpHerald(_ subordinate: ChirpHerald) {
        chirpHerald = subordinate
        subordinate.mediator = self
    }
    
    func registerWaddleScout(_ subordinate: WaddleScout) {
        waddleScout = subordinate
        subordinate.mediator = self
    }
    
    func registerPushTracker(_ subordinate: PushTracker) {
        pushTracker = subordinate
        subordinate.mediator = self
    }
    
    func registerTokenKeeper(_ subordinate: TokenKeeper) {
        tokenKeeper = subordinate
        subordinate.mediator = self
    }
    
    func kickstartBoot(
        messagingDelegate: MessagingDelegate,
        notificationDelegate: UNUserNotificationCenterDelegate,
        appsFlyerDelegate: AppsFlyerLibDelegate,
        deepLinkDelegate: DeepLinkDelegate
    ) {
        FirebaseApp.configure()
        
        Messaging.messaging().delegate = messagingDelegate
        UNUserNotificationCenter.current().delegate = notificationDelegate
        UIApplication.shared.registerForRemoteNotifications()
        
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = GlacierConstants.trackerKey
        sdk.appleAppID = GlacierConstants.appCode
        sdk.delegate = appsFlyerDelegate
        sdk.deepLinkDelegate = deepLinkDelegate
        sdk.isDebug = false
    }
    
    func kickActivation() {
        if #available(iOS 14, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
    
    func notify(_ event: MediatorEvent) {
        switch event {
        case .attributionReady:
            chirpHerald?.receive(event)
        case .deeplinkResolved:
            chirpHerald?.receive(event)
            waddleScout?.receive(event)
        case .pushArrived:
            pushTracker?.receive(event)
        case .tokenIssued:
            tokenKeeper?.receive(event)
        }
    }
}

final class ChirpHerald: FlockSubordinate {
    
    weak var mediator: FlockMediator?
    
    private var chirpsBuffer: [AnyHashable: Any] = [:]
    private var waddlesBuffer: [AnyHashable: Any] = [:]
    private var fuseTimer: Timer?
    
    func receive(_ event: MediatorEvent) {
        switch event {
        case .attributionReady(let data):
            chirpsBuffer = data
            scheduleFuse()
            if !waddlesBuffer.isEmpty { performFuse() }
            
        case .deeplinkResolved(let data):
            guard !UserDefaults.standard.bool(forKey: GlacierKey.primed) else { return }
            waddlesBuffer = data
            fuseTimer?.invalidate()
            if !chirpsBuffer.isEmpty { performFuse() }
            
        default:
            break
        }
    }
    
    private func scheduleFuse() {
        fuseTimer?.invalidate()
        fuseTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.performFuse()
        }
    }
    
    private func performFuse() {
        var combined = chirpsBuffer
        for (k, v) in waddlesBuffer {
            let prefixed = "deep_\(k)"
            if combined[prefixed] == nil {
                combined[prefixed] = v
            }
        }
        NotificationCenter.default.post(
            name: .init("ConversionDataReceived"),
            object: nil,
            userInfo: ["conversionData": combined]
        )
    }
}

// MARK: - WaddleScout (forwards deeplinks)

final class WaddleScout: FlockSubordinate {
    
    weak var mediator: FlockMediator?
    
    func receive(_ event: MediatorEvent) {
        guard case .deeplinkResolved(let data) = event else { return }
        NotificationCenter.default.post(
            name: .init("deeplink_values"),
            object: nil,
            userInfo: ["deeplinksData": data]
        )
    }
}

final class PushTracker: FlockSubordinate {
    
    weak var mediator: FlockMediator?
    
    func receive(_ event: MediatorEvent) {
        guard case .pushArrived(let payload) = event else { return }
        guard let url = extract(payload) else { return }
        
        UserDefaults.standard.set(url, forKey: GlacierKey.pushURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            NotificationCenter.default.post(
                name: .init("LoadTempURL"),
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }
    
    private func extract(_ payload: [AnyHashable: Any]) -> String? {
        if let direct = payload["url"] as? String { return direct }
        if let nested = payload["data"] as? [String: Any],
           let url = nested["url"] as? String { return url }
        if let aps = payload["aps"] as? [String: Any],
           let nested = aps["data"] as? [String: Any],
           let url = nested["url"] as? String { return url }
        if let custom = payload["custom"] as? [String: Any],
           let url = custom["target_url"] as? String { return url }
        return nil
    }
}

final class TokenKeeper: FlockSubordinate {
    
    weak var mediator: FlockMediator?
    
    func receive(_ event: MediatorEvent) {
        guard case .tokenIssued(let token) = event else { return }
        UserDefaults.standard.set(token, forKey: GlacierKey.fcm)
        UserDefaults.standard.set(token, forKey: GlacierKey.push)
        UserDefaults(suiteName: GlacierConstants.suiteGlacier)?.set(token, forKey: "shared_fcm")
    }
}
