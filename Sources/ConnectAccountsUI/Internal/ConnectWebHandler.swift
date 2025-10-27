//
//  ConnectWebHandler.swift
//  ConnectAccountsUI
//
//  Created by Morten Bjerg Gregersen on 21/10/2025.
//

import Foundation
import Observation
import WebKit

@MainActor @Observable
final class ConnectWebHandler {
    var callJavaScript: (String) async throws -> Any? = { _ in fatalError("callJavaScript not set") }
    private(set) var steps: [Step]
    var keyId: String = "" { didSet {
        let requiredLength = keyType == .individual ? 12 : 10
        if keyId.lengthOfBytes(using: .utf8) >= requiredLength {
            currentStep = .downloadKey
        }
    }}
    var issuerId: String = "" { didSet {
        if issuerId.lengthOfBytes(using: .utf8) >= 36 {
            guard let lastPolledURL else { return }
            startStepResolutionPolling(url: lastPolledURL)
        }
    }}
    var privateKey: String = ""
    var showsIndividualKeyNotSupportedAlert = false
    var showsTeamKeyNotSupportedAlert = false
    var keyType: KeyType { didSet {
        keyId = ""
        issuerId = ""
        privateKey = ""
        steps = Self.stepsForKeyType(keyType)
    }}
    private(set) var currentStep: Step? { didSet {
        if let oldValue {
            if oldValue == .copyKeyId, keyType == .individual {
                if let keyIdOriginalPadding,
                   let demanipulateScript = oldValue.demanipulateScript(withPadding: keyIdOriginalPadding, keyType: keyType) {
                    Task { @MainActor in
                        await self.runJavaScript(demanipulateScript)
                    }
                }
            } else if oldValue == .selectIntegrations || oldValue == .copyIssuerId || oldValue == .copyKeyId,
                      let demanipulateScript = oldValue.demanipulateScript(keyType: keyType) {
                Task { @MainActor in
                    await self.runJavaScript(demanipulateScript)
                }
            }
        }
        manipulateForCurrentStep()
    }}

    private static let basicSteps: [Step] = [.login, .selectUsersAndAccess]
    private var resolveStepTask: Task<Void, Never>?
    private var keyIdOriginalPadding: String?
    private var lastPolledURL: URL?

    init() {
        self.steps = Self.stepsForKeyType(.individual)
        self.keyType = .individual
    }

    func resolveStep(url: URL) async {
        var pages: [Page] = [UsersListPage(), MainPage(), LoginPage()]
        if keyType == .individual {
            pages = [UserDetailsPage()] + pages
        } else if keyType == .team {
            pages = [IntegrationsApiPage(), IntegrationsPage()] + pages
        }
        let urlString = url.absoluteString
        for page in pages {
            var results = [Bool]()
            for trait in page.traits {
                if Task.isCancelled { return }
                let result: Bool
                switch trait {
                case .javaScript(let string):
                    if Task.isCancelled { return }
                    result = await (try? callJavaScript("return \(string);") as? Bool) ?? false
                case .url(let string):
                    result = urlString == string
                case .urlPrefix(let string):
                    result = urlString.hasPrefix(string)
                case .urlSuffix(let string):
                    result = urlString.hasSuffix(string)
                }
                results.append(result)
            }
            guard results.allSatisfy({ $0 }) else { continue }
            if let nextStep = page.nextStep(keyType: keyType), nextStep != currentStep {
                currentStep = nextStep
                stopStepResolutionPolling()
            } else if page is UserDetailsPage, let currentStep,
                      let selectUserIndex = steps.firstIndex(of: .selectUser),
                      let currentIndex = steps.firstIndex(of: currentStep),
                      currentIndex >= selectUserIndex {
                if let script = Step.createKey.requiredDetectionScript(keyType: keyType),
                   let result = try? await callJavaScript(script) as? Bool, result,
                   currentStep != .createKey {
                    self.currentStep = .createKey
                } else if let script = Step.copyKeyId.requiredDetectionScript(keyType: keyType),
                          let result = try? await callJavaScript(script) as? Bool, result,
                          currentStep != .copyKeyId,
                          keyId.isEmpty {
                    self.currentStep = .copyKeyId
                } else if let script = Step.revokeKey.requiredDetectionScript(keyType: keyType),
                          let result = try? await callJavaScript(script) as? Bool, result,
                          !steps.contains(.revokeKey),
                          currentStep != .revokeKey {
                    steps.insert(.revokeKey, at: steps.index(after: currentIndex))
                    self.currentStep = .revokeKey
                } else if !privateKey.isEmpty {
                    stopStepResolutionPolling()
                } else if let result = try? await callJavaScript(Step.isIndividualApiKeyCreationAllowedScript) as? Bool,
                          result == false {
                    showsIndividualKeyNotSupportedAlert = true
                    stopStepResolutionPolling()
                }
            } else if page is IntegrationsPage,
                      let result = try? await callJavaScript(Step.isTeamApiKeyCreationAllowedScript(onApiPage: false)) as? Bool,
                      result == false {
                showsTeamKeyNotSupportedAlert = true
                stopStepResolutionPolling()
            } else if page is IntegrationsApiPage, let currentStep,
                      let selectIntegrationsIndex = steps.firstIndex(of: .selectIntegrations),
                      let currentIndex = steps.firstIndex(of: currentStep),
                      currentIndex >= selectIntegrationsIndex {
                if let script = Step.copyIssuerId.requiredDetectionScript(keyType: keyType),
                   let result = try? await callJavaScript(script) as? Bool, result,
                   currentStep != .copyIssuerId,
                   issuerId.isEmpty {
                    self.currentStep = .copyIssuerId
                } else if !issuerId.isEmpty,
                          let script = Step.copyKeyId.requiredDetectionScript(keyType: keyType),
                          let result = try? await callJavaScript(script) as? Bool, result,
                          currentStep != .copyKeyId,
                          keyId.isEmpty {
                    self.currentStep = .copyKeyId
                } else if let result = try? await callJavaScript(Step.isTeamApiKeyCreationAllowedScript(onApiPage: true)) as? Bool,
                          result == false {
                    showsTeamKeyNotSupportedAlert = true
                    stopStepResolutionPolling()
                } else if !privateKey.isEmpty {
                    stopStepResolutionPolling()
                }
            }
            return
        }
    }

    // MARK: - Callbacks from view/WebPage

    func loadingFinished() {
        manipulateForCurrentStep()
    }

    private func manipulateForCurrentStep() {
        if let currentStep, let manipulateScript = currentStep.manipulateScript(keyType: keyType) {
            Task { @MainActor in
                if currentStep == .copyKeyId, let getPaddingScript = currentStep.getPaddingScript {
                    self.keyIdOriginalPadding = await self.fetchString(getPaddingScript)
                }
                await self.runJavaScript(manipulateScript)
            }
        }
    }

    func urlChanged(newUrl: URL) async {
        // Avoid restarting polling if URL hasn’t changed
        guard newUrl != lastPolledURL else { return }
        lastPolledURL = newUrl
        startStepResolutionPolling(url: newUrl)
    }

    private func startStepResolutionPolling(url: URL, interval: Duration = .milliseconds(500)) {
        stopStepResolutionPolling()
        resolveStepTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await resolveStep(url: url)
                try? await Task.sleep(for: interval)
            }
        }
    }

    private func stopStepResolutionPolling() {
        resolveStepTask?.cancel()
        resolveStepTask = nil
    }

    // MARK: - JavaScript helpers (avoid capturing non-Sendable Any in Task closures)

    @MainActor
    private func runJavaScript(_ script: String) async {
        _ = try? await callJavaScript(script)
    }

    @MainActor
    private func fetchString(_ script: String) async -> String? {
        try? await callJavaScript(script) as? String
    }

    // MARK: - Steps for key type

    private static func stepsForKeyType(_ keyType: KeyType) -> [Step] {
        var steps = Self.basicSteps
        switch keyType {
        case .individual:
            steps.append(contentsOf: [.selectUser, .createKey, .copyKeyId, .downloadKey])
        case .team:
            steps.append(contentsOf: [.selectIntegrations, .copyIssuerId, .createKey, .copyKeyId, .downloadKey])
        }
        return steps
    }
}

@available(macOS 26.0, *)
extension ConnectWebHandler: WebPage.NavigationDeciding {
    func decidePolicy(for response: WebPage.NavigationResponse) async -> WKNavigationResponsePolicy {
        if response.response.url?.scheme == "data",
           let urlComponents = response.response.url?.absoluteString.split(separator: ","),
           urlComponents.count == 2 {
            let urlEncodedPrivateKey = urlComponents[1]
            if let decodedPrivateKey = String(urlEncodedPrivateKey).removingPercentEncoding {
                privateKey = decodedPrivateKey
            }
            return .cancel
        }
        return .allow
    }
}

private protocol Page {
    var traits: [Trait] { get }
    func nextStep(keyType: KeyType) -> Step?
}

private enum Trait {
    case javaScript(String)
    case url(String)
    case urlPrefix(String)
    case urlSuffix(String)
}

private struct LoginPage: Page {
    let traits = [Trait.url("https://appstoreconnect.apple.com/login")]
    func nextStep(keyType: KeyType) -> Step? {
        .login
    }
}

private struct MainPage: Page {
    let traits = [Trait.javaScript(#"document.querySelector('a[href="https://appstoreconnect.apple.com/access/users"]') !== null"#)]
    func nextStep(keyType: KeyType) -> Step? {
        .selectUsersAndAccess
    }
}

private struct UsersListPage: Page {
    let traits = [Trait.url("https://appstoreconnect.apple.com/access/users")]
    func nextStep(keyType: KeyType) -> Step? {
        switch keyType {
        case .individual: .selectUser
        case .team: .selectIntegrations
        }
    }
}

private struct UserDetailsPage: Page {
    let traits = [
        Trait.urlPrefix("https://appstoreconnect.apple.com/access/users"),
        Trait.urlSuffix("/settings")
    ]
    func nextStep(keyType: KeyType) -> Step? {
        nil
    }
}

private struct IntegrationsPage: Page {
    let traits = [Trait.url("https://appstoreconnect.apple.com/access/integrations")]
    func nextStep(keyType: KeyType) -> Step? {
        nil
    }
}

private struct IntegrationsApiPage: Page {
    let traits = [Trait.url("https://appstoreconnect.apple.com/access/integrations/api")]
    func nextStep(keyType: KeyType) -> Step? {
        nil
    }
}
