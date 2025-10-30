//
//  GenerateAPIKeyView.swift
//  ConnectAccountsUI
//
//  Created by Morten Bjerg Gregersen on 13/10/2025.
//

import SwiftUI
import WebKit

@available(macOS 26.0, iOS 26.0, *)
/// A SwiftUI view for generating an API key via App Store Connect.
public struct GenerateAPIKeyView: View {
    @State private var connectWebHandler = ConnectWebHandler()
    @State private var page: WebPage?
    @State private var showsInspector = false
    @State private var validateTaskId: UUID?
    @State private var isValidatingKey = false
    @State private var validationError: Error?
    @Environment(\.dismiss) private var dismiss
    private let apiKeyValidator: APIKeyValidator
    private let dismissOnValidationSuccess: Bool

    /**
     Initializes a new instance of `GenerateAPIKeyView`.

     - Parameters:
        - apiKeyValidator: An object conforming to `APIKeyValidator` for validating the API key.
        - dismissOnValidationSuccess: A Boolean indicating whether to dismiss the view upon successful validation.
     */
    public init(apiKeyValidator: APIKeyValidator, dismissOnValidationSuccess: Bool = true) {
        self.apiKeyValidator = apiKeyValidator
        self.dismissOnValidationSuccess = dismissOnValidationSuccess
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                #if os(macOS)
                HStack {
                    ControlGroup {
                        Button {
                            goBack()
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                                .labelStyle(.iconOnly)
                        }
                        .disabled(!canGoBack)
                        Button {
                            goForward()
                        } label: {
                            Label("Forward", systemImage: "chevron.right")
                                .labelStyle(.iconOnly)
                        }
                        .disabled(!canGoForward)
                    }
                    Text(page?.url?.absoluteString ?? "")
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                    Button {
                        page?.reload()
                    } label: {
                        Label("Reload", systemImage: "arrow.clockwise")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.borderless)
                    .disabled(page?.isLoading ?? true)
                    Button {
                        showsInspector.toggle()
                    } label: {
                        Label("Toggle steps list", systemImage: "list.bullet")
                            .labelStyle(.iconOnly)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .overlay(alignment: .bottom) {
                    if let page, page.estimatedProgress < 1.0 {
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(.quaternary)
                                    .frame(height: 4)
                                Rectangle()
                                    .fill(Color.accentColor)
                                    .frame(width: proxy.size.width * max(0, min(CGFloat(page.estimatedProgress), 1)), height: 4)
                            }
                        }
                        .frame(height: 4)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: page.estimatedProgress)
                    }
                }
                #endif
                if let page {
                    WebView(page)
                        .overlay(alignment: .bottom) {
                            if isValidatingKey || validationError != nil {
                                VStack {
                                    if isValidatingKey {
                                        ProgressView("Validating API Key...")
                                            .padding()
                                    } else if let validationError {
                                        Text("An error occurred")
                                            .font(.headline)
                                        Text(validationError.localizedDescription)
                                        HStack {
                                            Button("Cancel", role: .cancel) {
                                                self.validationError = nil
                                            }
                                            Button("Try again") {
                                                self.validationError = nil
                                                validateTaskId = UUID()
                                            }
                                            .buttonStyle(.borderedProminent)
                                        }
                                    }
                                }
                                .multilineTextAlignment(.center)
                                .padding()
                                .padding(.horizontal, 8)
                                .background(RoundedRectangle(cornerRadius: 16)
                                    .fill(Material.ultraThin)
                                )
                                .padding()
                            } else if !showsInspector, let currentStep = connectWebHandler.currentStep {
                                VStack {
                                    Text(currentStep.instruction)
                                        .font(.title)
                                    if let notes = currentStep.notes(keyType: connectWebHandler.keyType) {
                                        Text(notes)
                                    }
                                    if currentStep == .copyKeyId {
                                        TextField("Key ID", text: $connectWebHandler.keyId)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(maxWidth: 200)
                                    } else if currentStep == .copyIssuerId {
                                        TextField("Issuer ID", text: $connectWebHandler.issuerId)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(maxWidth: 300)
                                    }
                                }
                                .multilineTextAlignment(.center)
                                .padding()
                                .padding(.horizontal, 8)
                                .background(RoundedRectangle(cornerRadius: 16)
                                    .fill(Material.ultraThin)
                                )
                                .padding()
                            }
                        }
                } else {
                    ProgressView("Loading App Store Connect…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("App Store Connect")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                #if os(iOS)
                ToolbarItemGroup(placement: .navigation) {
                    Button {
                        goBack()
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                    }
                    .disabled(!canGoBack)
                    Button {
                        goForward()
                    } label: {
                        Label("Forward", systemImage: "chevron.right")
                    }
                    .disabled(!canGoForward)
                }
                ToolbarItem {
                    if let page, page.isLoading {
                        ProgressView()
                            .scaleEffect(0.5, anchor: .center)
                    } else {
                        Button {
                            page?.reload()
                        } label: {
                            Label("Reload", systemImage: "arrow.clockwise")
                        }
                    }
                }
                ToolbarSpacer()
                ToolbarItem {
                    Button {
                        showsInspector.toggle()
                    } label: {
                        Label("Toggle steps list", systemImage: "list.bullet")
                    }
                }
                ToolbarSpacer()
                #endif
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }
            }
            .alert("Can't create key", isPresented: $connectWebHandler.showsIndividualKeyNotSupportedAlert) {
                Button("OK", role: .cancel) {}
                Button("Create Team Key") {
                    page?.load(URL(string: "https://appstoreconnect.apple.com/access/users")!)
                    connectWebHandler.keyType = .team
                }
            } message: {
                Text("You are not allowed to create an individual API key. Contact your Admin to enable it for you or try to create a team API key.")
            }
            .alert("Can't create team key", isPresented: $connectWebHandler.showsTeamKeyNotSupportedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your account is not allowed to create team API keys. Contact your Account Holder to enable it.")
            }
            .animation(.default, value: connectWebHandler.currentStep)
            .task(id: page?.url) {
                guard let url = page?.url else { return }
                await connectWebHandler.urlChanged(newUrl: url)
            }
            .task {
                await setupWebPageIfNeeded()
                await startObservingEvents()
            }
            .task(id: validateTaskId) {
                guard validateTaskId != nil else { return }
                #if os(iOS)
                showsInspector = false
                #endif
                isValidatingKey = true

                let keyId = connectWebHandler.keyId
                let issuerId = connectWebHandler.issuerId.isEmpty ? nil : connectWebHandler.issuerId
                let privateKey = connectWebHandler.privateKey
                let creds = APIKeyCredentials(keyId: keyId, issuerId: issuerId, privateKey: privateKey)

                do {
                    try await apiKeyValidator.validateKey(credentials: creds)
                    if dismissOnValidationSuccess {
                        dismiss()
                    }
                } catch {
                    validationError = error
                }
                isValidatingKey = false
            }
            .onChange(of: connectWebHandler.privateKey) { _, _ in
                validateTaskId = UUID()
            }
            .onDisappear { page = nil }
        }
        .inspector(isPresented: $showsInspector) {
            NavigationStack {
                VStack(alignment: .leading) {
                    List {
                        ForEach(connectWebHandler.steps.enumerated(), id: \.0) { offset, step in
                            if let currentStep = connectWebHandler.currentStep {
                                let isBefore = step.isBefore(otherStep: currentStep)
                                Section {
                                    Text("\(offset + 1). \(step.instruction)")
                                        .foregroundStyle(step == connectWebHandler.currentStep ? .primary : .secondary)
                                        .bold(step == connectWebHandler.currentStep)
                                        .strikethrough(isBefore)
                                    if let notes = step.notes(keyType: connectWebHandler.keyType),
                                       connectWebHandler.currentStep == step {
                                        Text(notes)
                                    }
                                    if step == Step.copyIssuerId, currentStep == step || !connectWebHandler.issuerId.isEmpty {
                                        TextField("Issuer ID", text: $connectWebHandler.issuerId)
                                            .textFieldStyle(.roundedBorder)
                                    } else if step == Step.copyKeyId, currentStep == step || !connectWebHandler.keyId.isEmpty {
                                        TextField("Key ID", text: $connectWebHandler.keyId)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Steps")
                    .toolbar {
                        #if os(iOS)
                        if UIDevice.current.userInterfaceIdiom == .phone {
                            Button(role: .close) {
                                showsInspector = false
                            }
                        }
                        #endif
                    }
                }
            }
        }
    }

    @MainActor
    private func setupWebPageIfNeeded() async {
        guard page == nil else { return }
        var configuration = WebPage.Configuration()
        configuration.websiteDataStore = .default()
        let page = WebPage(configuration: configuration, navigationDecider: connectWebHandler)
        #if DEBUG
        page.isInspectable = true
        #endif
        connectWebHandler.callJavaScript = { try await page.callJavaScript($0) }
        page.load(URL(string: "https://appstoreconnect.apple.com")!)
        self.page = page
    }

    private var canGoBack: Bool {
        guard let page else { return false }
        return !page.backForwardList.backList.isEmpty
    }

    private func goBack() {
        guard let page, let item = page.backForwardList.backList.last else { return }
        page.load(item)
    }

    private var canGoForward: Bool {
        guard let page else { return false }
        return !page.backForwardList.forwardList.isEmpty
    }

    private func goForward() {
        guard let page, let item = page.backForwardList.forwardList.first else { return }
        page.load(item)
    }

    @MainActor
    private func startObservingEvents() async {
        guard let page else { return }
        do {
            for try await event in page.navigations {
                if event == .finished {
                    connectWebHandler.loadingFinished()
                }
            }
        } catch {}
    }
}

#Preview {
    if #available(macOS 26.0, iOS 26.0, *) {
        GenerateAPIKeyView(apiKeyValidator: PreviewAPIKeyValidator())
    } else {
        Text("Only available on macOS/iOS 26+.")
    }
}

@MainActor
private class PreviewAPIKeyValidator: APIKeyValidator {
    func validateKey(credentials: APIKeyCredentials) async throws {}
}

