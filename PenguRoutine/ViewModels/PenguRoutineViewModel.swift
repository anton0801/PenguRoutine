import Foundation
import Combine

@MainActor
final class PenguRoutineViewModel: ObservableObject {
    
    @Published var navigateToMain = false {
        didSet {
            if navigateToMain {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var navigateToWeb = false {
        didSet {
            if navigateToWeb {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    
    private let engine: WorkflowEngine
    private var cancellables = Set<AnyCancellable>()
    private var deadlineTask: Task<Void, Never>?
    
    private var uiLocked: Bool = false
    
    init() {
        self.engine = WorkflowEngine()
        wireUp()
    }
    
    deinit {
        deadlineTask?.cancel()
    }
    
    private func wireUp() {
        engine.outcomePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] outcome in
                self?.handleOutcome(outcome)
            }
            .store(in: &cancellables)
    }
    
    func boot() {
        engine.warmUp()
        armDeadline()
    }
    
    func ingestAttribution(_ data: [String: Any]) {
        Task {
            engine.ingestChirps(data)
            await engine.runWorkflow()
        }
    }
    
    func ingestDeeplinks(_ data: [String: Any]) {
        engine.ingestWaddles(data)
    }
    
    func acceptConsent() {
        engine.acceptConsent {
            self.showPermissionPrompt = false
        }
    }
    
    func skipConsent() {
        engine.deferConsent()
        showPermissionPrompt = false
    }
    
    func networkConnectivityChanged(_ connected: Bool) {
        showOfflineView = !connected
    }
    
    private func handleOutcome(_ outcome: RoutineOutcome) {
        guard !uiLocked else {
            return
        }
        
        switch outcome {
        case .huddled:
            break
        case .requestConsent:
            showPermissionPrompt = true
        case .openFloes:
            navigateToWeb = true
        case .driftedToColony:
            navigateToMain = true
        }
    }
    
    private func armDeadline() {
        deadlineTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            guard let self = self else { return }
            
            let shouldFire = self.engine.reportBeaconExpired()
            if shouldFire {
                self.handleOutcome(.driftedToColony)
            }
        }
    }
}
