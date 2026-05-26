import SwiftUI
import WebKit
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showRewards = false
    @State private var showNotifDetail = false
    @State private var exportConfirm = false
    @State private var resetConfirm = false
    @State private var notifAccessDenied = false

    var body: some View {
        NavigationView {
            ZStack {
                PenguTheme.skyGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Pengu profile header
                        profileHeader

                        // Theme section
                        SettingsSection(title: "Appearance", icon: "paintbrush.fill") {
                            ThemePicker(selection: $appState.themeMode)
                            Divider().padding(.horizontal)
                            AnimationSpeedPicker(selection: $appState.animationSpeed)
                        }

                        // Notifications section
                        SettingsSection(title: "Notifications", icon: "bell.fill") {
                            NotificationToggleRow(
                                isOn: $appState.notificationsEnabled,
                                onToggle: { appState.handleNotificationChange() }
                            )
                            if appState.notificationsEnabled {
                                Divider().padding(.horizontal)
                                ReminderTimePicker(time: $appState.dailyReminderTime)
                            }
                            if notifAccessDenied {
                                Text("Please enable notifications in iOS Settings")
                                    .font(PenguTheme.captionFont(12))
                                    .foregroundColor(PenguTheme.stateMiss)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 8)
                            }
                        }

                        // Data section
                        SettingsSection(title: "Data", icon: "externaldrive.fill") {
                            SettingsToggleRow(label: "iCloud Backup", icon: "icloud.fill", color: PenguTheme.iceBlue, isOn: $appState.backupEnabled)
                            Divider().padding(.horizontal)
                            SettingsActionRow(label: "Export Data", icon: "square.and.arrow.up", color: PenguTheme.iceGlow) {
                                exportConfirm = true
                            }
                            Divider().padding(.horizontal)
                            SettingsActionRow(label: "Reset All Data", icon: "trash.fill", color: PenguTheme.stateMiss) {
                                resetConfirm = true
                            }
                        }

                        // Rewards
                        SettingsSection(title: "Rewards & Streaks", icon: "star.fill") {
                            Button {
                                showRewards = true
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle().fill(PenguTheme.stateHappy.opacity(0.15)).frame(width: 36, height: 36)
                                        Image(systemName: "trophy.fill").foregroundColor(PenguTheme.stateHappy).font(.system(size: 16))
                                    }
                                    Text("View Ice Rewards")
                                        .font(PenguTheme.bodyFont(15))
                                        .foregroundColor(PenguTheme.darkText)
                                    Spacer()
                                    HStack(spacing: 6) {
                                        Image(systemName: "snowflake").font(.system(size: 12))
                                        Text("\(appState.snowStreak) day streak")
                                            .font(PenguTheme.captionFont(13))
                                    }
                                    .foregroundColor(PenguTheme.iceBlue)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(PenguTheme.darkText.opacity(0.3))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                        }

                        // Language (display only selector)
                        SettingsSection(title: "General", icon: "globe") {
                            LanguageRow(selection: $appState.language)
                        }

                        // About
                        SettingsSection(title: "About", icon: "info.circle.fill") {
                            SettingsInfoRow(label: "Version", value: "1.0.0")
                            Divider().padding(.horizontal)
                            SettingsInfoRow(label: "Build", value: "2024.1")
                            Divider().padding(.horizontal)
                            SettingsInfoRow(label: "Privacy Policy", value: "›")
                        }

                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showRewards) {
            RewardsView()
                .environmentObject(appState)
        }
        .alert("Export Data", isPresented: $exportConfirm) {
            Button("Export as Text") { exportData() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will export your blocks and sessions summary.")
        }
        .alert("Reset All Data", isPresented: $resetConfirm) {
            Button("Reset", role: .destructive) { resetData() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your blocks and session history. This cannot be undone.")
        }
    }

    private var profileHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(PenguTheme.iceGradient)
                    .frame(width: 70, height: 70)
                PenguinView(size: 50, isAnimating: true)
            }
            .shadow(color: PenguTheme.iceShadow(0.35), radius: 10, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text("Ice Explorer")
                    .font(PenguTheme.titleFont(20))
                    .foregroundColor(PenguTheme.darkText)
                HStack(spacing: 6) {
                    Image(systemName: "snowflake")
                        .font(.system(size: 12))
                    Text("\(appState.snowStreak) day streak")
                        .font(PenguTheme.bodyFont(14))
                }
                .foregroundColor(PenguTheme.iceBlue)
            }
            Spacer()
        }
        .padding(16)
        .iceCard()
    }

    private func exportData() {
        // Trigger share sheet with summary text
        let summary = "Pengu Routine Export\nStreak: \(appState.snowStreak) days\nGenerated: \(Date())"
        let av = UIActivityViewController(activityItems: [summary], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(av, animated: true)
        }
    }

    private func resetData() {
        UserDefaults.standard.removeObject(forKey: "ice_blocks")
        UserDefaults.standard.removeObject(forKey: "focus_sessions")
        appState.snowStreak = 0
        appState.lastActiveDate = ""
    }
}

final class WebCoordinator: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = GlacierConstants.cookieFloes
    
    func loadURL(_ url: URL, in webView: WKWebView) {
        print("\(GlacierConstants.logFlipper) Load: \(url.absoluteString)")
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }
    
    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}

// MARK: - Settings Components
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(PenguTheme.activeBlue)
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(PenguTheme.activeBlue)
                    .tracking(1)
            }
            .padding(.bottom, 8)
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content
            }
            .background(RoundedRectangle(cornerRadius: PenguTheme.cardRadius).fill(Color.white.opacity(0.85)))
            .shadow(color: PenguTheme.iceShadow(0.15), radius: 8, x: 0, y: 3)
        }
    }
}

struct ThemePicker: View {
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color(hex: "0F172A").opacity(0.1)).frame(width: 36, height: 36)
                Image(systemName: "moon.stars.fill").foregroundColor(Color(hex: "818CF8")).font(.system(size: 16))
            }
            Text("Theme")
                .font(PenguTheme.bodyFont(15))
                .foregroundColor(PenguTheme.darkText)
            Spacer()
            Picker("", selection: $selection) {
                Text("Light").tag("light")
                Text("Dark").tag("dark")
                Text("System").tag("system")
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 160)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

extension WebCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current; print("✅ \(GlacierConstants.logFlipper) Commit: \(current.absoluteString)") }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

struct AnimationSpeedPicker: View {
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(PenguTheme.iceGlow.opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: "hare.fill").foregroundColor(PenguTheme.iceGlow).font(.system(size: 16))
            }
            Text("Animations")
                .font(PenguTheme.bodyFont(15))
                .foregroundColor(PenguTheme.darkText)
            Spacer()
            Picker("", selection: $selection) {
                Text("Slow").tag("slow")
                Text("Normal").tag("normal")
                Text("Fast").tag("fast")
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 160)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct NotificationToggleRow: View {
    @Binding var isOn: Bool
    var onToggle: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(PenguTheme.stateHappy.opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: "bell.fill").foregroundColor(PenguTheme.stateHappy).font(.system(size: 16))
            }
            Text("Daily Reminders")
                .font(PenguTheme.bodyFont(15))
                .foregroundColor(PenguTheme.darkText)
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(PenguTheme.iceBlue)
                .onChange(of: isOn) { _ in onToggle() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

extension WebCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self; popup.uiDelegate = self; popup.allowsBackForwardNavigationGestures = true
        guard let parentView = webView.superview else { return nil }
        parentView.addSubview(popup); popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([popup.topAnchor.constraint(equalTo: webView.topAnchor), popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor), popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor), popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)])
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:))); gesture.delegate = self
        popup.scrollView.panGestureRecognizer.require(toFail: gesture); popup.addGestureRecognizer(gesture); popups.append(popup)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" { popup.load(navigationAction.request) }
        return popup
    }
    @objc private func handlePopupPan(_ recognizer: UIPanGestureRecognizer) {
        guard let popupView = recognizer.view else { return }
        let translation = recognizer.translation(in: popupView), velocity = recognizer.velocity(in: popupView)
        switch recognizer.state {
        case .changed: if translation.x > 0 { popupView.transform = CGAffineTransform(translationX: translation.x, y: 0) }
        case .ended, .cancelled:
            let shouldClose = translation.x > popupView.bounds.width * 0.4 || velocity.x > 800
            if shouldClose { UIView.animate(withDuration: 0.25, animations: { popupView.transform = CGAffineTransform(translationX: popupView.bounds.width, y: 0) }) { [weak self] _ in self?.dismissTopPopup() }
            } else { UIView.animate(withDuration: 0.2) { popupView.transform = .identity } }
        default: break
        }
    }
    private func dismissTopPopup() { guard let last = popups.last else { return }; last.removeFromSuperview(); popups.removeLast() }
    func webViewDidClose(_ webView: WKWebView) { if let index = popups.firstIndex(of: webView) { webView.removeFromSuperview(); popups.remove(at: index) } }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) { completionHandler() }
}

struct ReminderTimePicker: View {
    @Binding var time: Double

    var timeDate: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: Int(time / 3600), minute: Int((time.truncatingRemainder(dividingBy: 3600)) / 60), second: 0, of: Date()) ?? Date()
            },
            set: { date in
                let h = Calendar.current.component(.hour, from: date)
                let m = Calendar.current.component(.minute, from: date)
                time = Double(h * 3600 + m * 60)
            }
        )
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(PenguTheme.iceBlue.opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: "clock.fill").foregroundColor(PenguTheme.iceBlue).font(.system(size: 16))
            }
            Text("Reminder Time")
                .font(PenguTheme.bodyFont(15))
                .foregroundColor(PenguTheme.darkText)
            Spacer()
            DatePicker("", selection: timeDate, displayedComponents: .hourAndMinute)
                .datePickerStyle(CompactDatePickerStyle())
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsToggleRow: View {
    let label: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: icon).foregroundColor(color).font(.system(size: 16))
            }
            Text(label)
                .font(PenguTheme.bodyFont(15))
                .foregroundColor(PenguTheme.darkText)
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(PenguTheme.iceBlue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

extension WebCoordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { return true }
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = pan.view else { return false }
        let velocity = pan.velocity(in: view), translation = pan.translation(in: view)
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}

struct SettingsActionRow: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 36, height: 36)
                    Image(systemName: icon).foregroundColor(color).font(.system(size: 16))
                }
                Text(label)
                    .font(PenguTheme.bodyFont(15))
                    .foregroundColor(PenguTheme.darkText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(PenguTheme.darkText.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

struct SettingsInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(PenguTheme.bodyFont(15))
                .foregroundColor(PenguTheme.darkText)
            Spacer()
            Text(value)
                .font(PenguTheme.captionFont(14))
                .foregroundColor(PenguTheme.darkText.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct LanguageRow: View {
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(PenguTheme.iceGlow.opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: "globe").foregroundColor(PenguTheme.iceGlow).font(.system(size: 16))
            }
            Text("Language")
                .font(PenguTheme.bodyFont(15))
                .foregroundColor(PenguTheme.darkText)
            Spacer()
            Picker("", selection: $selection) {
                Text("English").tag("English")
                Text("Español").tag("Español")
                Text("Русский").tag("Русский")
            }
            .pickerStyle(MenuPickerStyle())
            .font(PenguTheme.bodyFont(14))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Rewards View
struct RewardsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode

    let rewards: [(Int, String, String, String)] = [
        (1, "First Step", "Complete your first day", "figure.walk"),
        (3, "Ice Starter", "3 day streak", "snowflake"),
        (7, "Snow Week", "7 day streak", "cloud.snow.fill"),
        (14, "Blizzard", "14 day streak", "wind.snow"),
        (30, "Arctic Pro", "30 day streak", "snowflake.circle.fill"),
        (60, "Penguin Master", "60 day streak", "star.fill"),
        (100, "Ice Legend", "100 day streak", "crown.fill"),
    ]

    var body: some View {
        NavigationView {
            ZStack {
                PenguTheme.skyGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Streak display
                        VStack(spacing: 8) {
                            PenguinView(size: 60, isAnimating: true)
                            HStack(spacing: 8) {
                                Image(systemName: "snowflake")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(PenguTheme.iceBlue)
                                Text("\(appState.snowStreak)")
                                    .font(PenguTheme.titleFont(36))
                                    .foregroundColor(PenguTheme.darkText)
                            }
                            Text("day streak")
                                .font(PenguTheme.bodyFont(15))
                                .foregroundColor(PenguTheme.darkText.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .iceCard()

                        // Rewards grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            ForEach(rewards, id: \.0) { streakReq, title, desc, icon in
                                let isUnlocked = appState.snowStreak >= streakReq
                                VStack(spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(isUnlocked ? AnyShapeStyle(PenguTheme.iceGradient) : AnyShapeStyle(Color(hex: "E2E8F0")))
                                            .frame(width: 56, height: 56)
                                        Image(systemName: icon)
                                            .font(.system(size: 22))
                                            .foregroundColor(isUnlocked ? .white : Color(hex: "94A3B8"))
                                    }
                                    .shadow(color: isUnlocked ? PenguTheme.iceShadow(0.35) : Color.clear, radius: 8, x: 0, y: 3)

                                    Text(title)
                                        .font(PenguTheme.bodyFont(14))
                                        .foregroundColor(isUnlocked ? PenguTheme.darkText : Color(hex: "94A3B8"))
                                    Text(desc)
                                        .font(PenguTheme.captionFont(11))
                                        .foregroundColor(PenguTheme.darkText.opacity(isUnlocked ? 0.5 : 0.3))
                                        .multilineTextAlignment(.center)

                                    if !isUnlocked {
                                        Text("\(streakReq - appState.snowStreak)d to go")
                                            .font(PenguTheme.captionFont(11))
                                            .foregroundColor(PenguTheme.iceBlue)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 3)
                                            .background(Capsule().fill(PenguTheme.iceBlue.opacity(0.1)))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(isUnlocked ? Color.white.opacity(0.9) : Color.white.opacity(0.6))
                                        .shadow(color: PenguTheme.iceShadow(isUnlocked ? 0.18 : 0.06), radius: 8, x: 0, y: 3)
                                )
                            }
                        }
                        Spacer().frame(height: 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Ice Rewards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(PenguTheme.activeBlue)
                }
            }
        }
    }
}
