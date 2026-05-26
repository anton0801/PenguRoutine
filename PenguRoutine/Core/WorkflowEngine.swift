import Foundation
import Combine
import AppsFlyerLib

// MARK: - Step Result

enum StepResult {
    case proceed
    case branchTo(String)
    case settle(RoutineOutcome)
    case stumble(RoutineFault)
}

struct WorkflowStep {
    let id: String
    let condition: (GlacierSnapshot) -> Bool
    let body: (Atomic<GlacierSnapshot>, ServiceContainer) async -> StepResult
    let nextResolver: (StepResult) -> String?
}

enum StepID {
    static let pushCheck = "pushCheck"
    static let voltageSentinel = "voltageSentinel"
    static let organicSlippery = "organicSlippery"
    static let floesScouting = "floesScouting"
}

@MainActor
enum StepDefinitions {
    
    static func makePushCheckStep() -> WorkflowStep {
        WorkflowStep(
            id: StepID.pushCheck,
            condition: { _ in true },
            body: { state, services in
                guard let pushURL = UserDefaults.standard.string(forKey: GlacierKey.pushURL),
                      !pushURL.isEmpty else {
                    return .proceed
                }
                
                let needsConsent = state.read { $0.consentRipe }
                
                state.mutate { snap in
                    snap.floesURL = pushURL
                    snap.floesMode = "Active"
                    snap.untrodden = false
                    snap.camped = true
                }
                
                let snapshot = state.read { $0.freeze() }
                services.vault.stash(snapshot)
                services.vault.stashFloes(url: pushURL, mode: "Active")
                services.vault.markPrimed()
                UserDefaults.standard.removeObject(forKey: GlacierKey.pushURL)
                
                return .settle(needsConsent ? .requestConsent : .openFloes)
            },
            nextResolver: { result in
                if case .proceed = result { return StepID.voltageSentinel }
                return nil
            }
        )
    }
    
    static func makeVoltageSentinelStep() -> WorkflowStep {
        WorkflowStep(
            id: StepID.voltageSentinel,
            condition: { $0.chirpsReady },
            body: { state, services in
                do {
                    let verdict = try await services.sentinel.sentinelWatch()
                    if verdict {
                        return .proceed
                    } else {
                        return .stumble(.voltageDimmed)
                    }
                } catch let fault as RoutineFault {
                    return .stumble(fault)
                } catch {
                    return .stumble(.voltageDimmed)
                }
            },
            nextResolver: { result in
                if case .proceed = result {
                    return StepID.organicSlippery
                }
                return nil
            }
        )
    }
    
    static func makeOrganicSlipperyStep() -> WorkflowStep {
        WorkflowStep(
            id: StepID.organicSlippery,
            condition: { snap in
                snap.organicFloe && snap.untrodden && !snap.slipperyDone
            },
            body: { state, services in
                state.mutate { $0.slipperyDone = true }
                
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                
                let isCamped = state.read { $0.camped }
                guard !isCamped else {
                    return .proceed
                }
                
                let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
                
                do {
                    var fetched = try await services.attribution.ping(deviceID: deviceID)
                    
                    let waddles = state.read { $0.waddles }
                    for (k, v) in waddles {
                        if fetched[k] == nil {
                            fetched[k] = v
                        }
                    }
                    
                    let mapped = fetched.mapValues { "\($0)" }
                    state.mutate { $0.chirps = mapped }
                    
                    let snapshot = state.read { $0.freeze() }
                    services.vault.stash(snapshot)
                } catch {
                }
                
                return .proceed
            },
            nextResolver: { result in
                if case .proceed = result { return StepID.floesScouting }
                return nil
            }
        )
    }
    
    static func makeFloesScoutingStep() -> WorkflowStep {
        WorkflowStep(
            id: StepID.floesScouting,
            condition: { $0.chirpsReady && !$0.camped },
            body: { state, services in
                let chirps = state.read { $0.chirps }
                let seed = chirps.mapValues { $0 as Any }
                
                do {
                    let url = try await services.scout.scout(seed: seed)
                    
                    let needsConsent = state.read { $0.consentRipe }
                    
                    state.mutate { snap in
                        snap.floesURL = url
                        snap.floesMode = "Active"
                        snap.untrodden = false
                        snap.camped = true
                    }
                    
                    let snapshot = state.read { $0.freeze() }
                    services.vault.stash(snapshot)
                    services.vault.stashFloes(url: url, mode: "Active")
                    services.vault.markPrimed()
                    UserDefaults.standard.removeObject(forKey: GlacierKey.pushURL)
                    
                    return .settle(needsConsent ? .requestConsent : .openFloes)
                } catch let fault as RoutineFault {
                    return .stumble(fault)
                } catch {
                    return .stumble(.wireFrozen(attempts: 0))
                }
            },
            nextResolver: { _ in nil }
        )
    }
}

@MainActor
final class WorkflowEngine {
    
    let state: Atomic<GlacierSnapshot>
    
    private let outcomeSubject = PassthroughSubject<RoutineOutcome, Never>()
    var outcomePublisher: AnyPublisher<RoutineOutcome, Never> {
        outcomeSubject.eraseToAnyPublisher()
    }
    
    private var sequenceCompleted: Bool = false
    
    let services: ServiceContainer
    
    private var stepRegistry: [String: WorkflowStep] = [:]
    
    init(services: ServiceContainer = ServiceContainer()) {
        self.services = services
        self.state = Atomic(GlacierSnapshot(), label: "com.pengu.routine.state")
        
        let steps: [WorkflowStep] = [
            StepDefinitions.makePushCheckStep(),
            StepDefinitions.makeVoltageSentinelStep(),
            StepDefinitions.makeOrganicSlipperyStep(),
            StepDefinitions.makeFloesScoutingStep()
        ]
        for step in steps {
            stepRegistry[step.id] = step
        }
    }
    
    func warmUp() {
        let record = services.vault.thaw()
        state.replace(GlacierSnapshot.hydrate(from: record))
    }
    
    func ingestChirps(_ raw: [String: Any]) {
        let mapped = raw.mapValues { "\($0)" }
        state.mutate { $0.chirps = mapped }
        let snapshot = state.read { $0.freeze() }
        services.vault.stash(snapshot)
    }
    
    func ingestWaddles(_ raw: [String: Any]) {
        let mapped = raw.mapValues { "\($0)" }
        state.mutate { $0.waddles = mapped }
        let snapshot = state.read { $0.freeze() }
        services.vault.stash(snapshot)
    }
    
    func runWorkflow() async {
        guard !sequenceCompleted else { return }
        
        var currentStepID: String? = StepID.pushCheck
        var iterations = 0
        let maxIterations = 12
        
        while let stepID = currentStepID, iterations < maxIterations {
            iterations += 1
            
            if sequenceCompleted { return }
            
            guard let step = stepRegistry[stepID] else {
                break
            }
            
            let snap = state.value
            guard step.condition(snap) else {
                currentStepID = step.nextResolver(.proceed)
                continue
            }
            
            let result = await step.body(state, services)
            
            switch result {
            case .proceed:
                currentStepID = step.nextResolver(.proceed)
                
            case .branchTo(let targetID):
                currentStepID = targetID
                
            case .settle(let outcome):
                sequenceCompleted = true
                outcomeSubject.send(outcome)
                return
                
            case .stumble(let fault):
                sequenceCompleted = true
                outcomeSubject.send(.driftedToColony)
                return
            }
        }
        
        if iterations >= maxIterations {
            sequenceCompleted = true
            outcomeSubject.send(.driftedToColony)
            return
        }
        
        if !sequenceCompleted {
            print("\(GlacierConstants.logFlipper) Workflow ended — waiting for more triggers")
        }
    }
    
    func acceptConsent(b: @escaping () -> Void) {
        Task { [weak self] in
            guard let self = self else { return }
            
            let priorChilled = self.state.read { $0.consentChilled }
            let priorThawed = self.state.read { $0.consentThawed }
            
            let granted = await self.services.chirper.chirp()
            let now = Date()
            
            self.state.mutate { snap in
                if granted {
                    snap.consentChilled = true
                    snap.consentThawed = false
                    snap.consentMarkedAt = now
                } else {
                    snap.consentChilled = false
                    snap.consentThawed = true
                    snap.consentMarkedAt = now
                }
            }
            
            if granted {
                self.services.chirper.armPushSignal()
            }
            
            _ = priorChilled
            _ = priorThawed
            
            let snapshot = self.state.read { $0.freeze() }
            self.services.vault.stash(snapshot)
            self.outcomeSubject.send(.openFloes)
            b()
        }
    }
    
    func deferConsent() {
        let now = Date()
        state.mutate { $0.consentMarkedAt = now }
        let snapshot = state.read { $0.freeze() }
        services.vault.stash(snapshot)
        outcomeSubject.send(.openFloes)
    }
    
    func reportBeaconExpired() -> Bool {
        guard !sequenceCompleted else {
            return false
        }
        sequenceCompleted = true
        return true
    }
}
