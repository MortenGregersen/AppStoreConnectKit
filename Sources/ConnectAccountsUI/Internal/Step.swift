//
//  Step.swift
//  ConnectAccountsUI
//
//  Created by Morten Bjerg Gregersen on 27/10/2025.
//

import Foundation

/// Enumeration representing the steps to generate an API key.
enum Step: CaseIterable {
    case login
    case selectUsersAndAccess
    // For individual keys
    case selectUser
    case revokeKey
    // For team keys
    case selectIntegrations
    case copyIssuerId
    // For all keys
    case createKey
    case copyKeyId
    case downloadKey

    /// Instruction text for the step.
    var instruction: String {
        switch self {
        case .login: "Login to App Store Connect"
        case .selectUsersAndAccess: "Go to Users and Access"
        case .selectUser: "Select your user in the list"
        case .selectIntegrations: "Go to Integrations"
        case .createKey: "Generate API Key"
        case .revokeKey: "Revoke Existing Key"
        case .copyKeyId: "Copy Key ID"
        case .copyIssuerId: "Copy Issuer ID"
        case .downloadKey: "Download Private Key"
        }
    }

    /**
     Additional notes for the step.

     - Parameter keyType: The type of API key being created (individual or team).
     */
    func notes(keyType: KeyType?) -> AttributedString? {
        if self == .revokeKey {
            AttributedString("You already have an existing API key. It must be revoked before you can create a new one.")
        } else if self == .createKey, keyType == .team {
            try! AttributedString(markdown: "Select a fitting role. Read more about the roles on [Apples website](https://developer.apple.com/help/app-store-connect/reference/role-permissions).")
        } else {
            nil
        }
    }

    /**
     Returns true if this step comes before the other step in the defined order.

     - Parameter otherStep: The other step to compare with.
     */
    func isBefore(otherStep: Step) -> Bool {
        guard let selfIndex = Step.allCases.firstIndex(of: self),
              let otherIndex = Step.allCases.firstIndex(of: otherStep) else {
            return false
        }
        return selfIndex < otherIndex
    }

    /**
     JavaScript that returns true if the step is currently applicable.

     - Parameter keyType: The type of API key being created (individual or team).
     */
    func requiredDetectionScript(keyType: KeyType) -> String? {
        if self == .revokeKey {
            """
            \(Self.awaitNoProgressBar)
            \(Self.findIndividualApiKeySection)
            return !\(ElementName.downloadButton) && !\(ElementName.generateNewKeyButton) && !!\(ElementName.revokeButton);
            """
        } else if self == .createKey {
            """
            \(Self.awaitNoProgressBar)
            \(Self.findIndividualApiKeySection)
            return !!\(ElementName.generateNewKeyButton);
            """
        } else if self == .copyIssuerId {
            """
            \(Self.awaitNoProgressBar)
            \(Self.findTeamIssuerId)
            return !!\(ElementName.custom("issuerId"));
            """
        } else if self == .copyKeyId {
            switch keyType {
            case .team:
                """
                \(Self.awaitNoProgressBar)
                \(Self.findTeamNewApiKeySection)
                return !!\(ElementName.downloadButton);
                """
            case .individual:
                """
                \(Self.awaitNoProgressBar)
                \(Self.findIndividualApiKeySection)
                return !!\(ElementName.downloadButton);
                """
            }
        } else {
            nil
        }
    }

    /// JavaScript that gets the current padding of the Key ID element.
    var getPaddingScript: String? {
        if self == .copyKeyId {
            """
            \(Self.awaitNoProgressBar)
            \(Self.findIndividualApiKeySection)
            \(Self.findIndividualKeyId)
            return getComputedStyle(keyId).padding;
            """
        } else {
            nil
        }
    }

    /**
     JavaScript that removes the styling added in manipulateScript.

     - Parameters:
        - padding: The padding to restore to the element (default is "0px").
        - keyType: The type of API key being created.
     */
    func demanipulateScript(withPadding padding: String = "0px", keyType: KeyType) -> String? {
        if self == .selectIntegrations {
            """
            const compactMenu = document.querySelector('nav[aria-label="Users and Access"]');
            \(Self.styleIfPresent(.custom("compactMenu"), border: false))
            const link = document.querySelector('a[href="/access/integrations"]');
            \(Self.styleIfPresent(.custom("link"), border: false))
            """
        } else if self == .copyIssuerId {
            """
            \(Self.findTeamIssuerId)
            \(Self.styleIfPresent(.custom("issuerId"), border: false))
            """
        } else if self == .copyKeyId {
            switch keyType {
            case .individual:
                """
                \(Self.findIndividualKeyId)
                \(Self.styleIfPresent(.custom("keyId"), padding: padding, border: false))
                """
            case .team:
                """
                \(Self.findTeamNewApiKeySection)
                \(Self.styleIfPresent(.custom("keyId"), border: false))
                """
            }
        } else {
            nil
        }
    }

    /**
     JavaScript that highlights and scrolls to the relevant element for the step.

     - Parameter keyType: The type of API key being created.
     */
    func manipulateScript(keyType: KeyType) -> String? {
        if self == .selectUsersAndAccess {
            """
            \(Self.awaitNoProgressBar)
            const link = document.querySelector('a[href="https://appstoreconnect.apple.com/access/users"]');
            const parentDiv = link?.closest('div');
            \(Self.styleIfPresent(.custom("parentDiv"), padding: "0px"))
            \(Self.scrollToIfPresent(.custom("parentDiv")))
            """
        } else if self == .selectIntegrations {
            """
            const menuSelector = 'nav[aria-label="Users and Access"]';
            while (document.querySelectorAll(menuSelector).length == 0) {
                await new Promise(r => setTimeout(r, 200));
            }
            \(Self.awaitNoProgressBar)
            const menu = document.querySelector(menuSelector);
            const containerDiv = menu?.closest('div');
            if (containerDiv && containerDiv.style.transform == '') {
                \(Self.styleIfPresent(.custom("menu")))
            }
            const link = document.querySelector('a[href="/access/integrations"]');
            \(Self.styleIfPresent(.custom("link")))
            """
        } else if self == .revokeKey {
            """
            \(Self.awaitNoProgressBar)
            \(Self.findIndividualApiKeySection)
            \(Self.styleIfPresent(.revokeButton))
            \(Self.scrollToIfPresent(.header))
            """
        } else if self == .createKey {
            switch keyType {
            case .individual:
                """
                \(Self.awaitNoProgressBar)
                \(Self.findIndividualApiKeySection)
                \(Self.styleIfPresent(.generateNewKeyButton))
                \(Self.scrollToIfPresent(.header))
                """
            case .team:
                """
                \(Self.awaitNoProgressBar)
                const button = document.evaluate(
                    './/h3[starts-with(normalize-space(), "Active")]/following-sibling::button[1]',
                    document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null
                ).singleNodeValue;
                \(Self.styleIfPresent(.custom("button"), padding: "12px"))
                """
            }
        } else if self == .copyIssuerId {
            """
            \(Self.awaitNoProgressBar)
            \(Self.findTeamIssuerId)
            \(Self.styleIfPresent(.custom("issuerId")))
            """
        } else if self == .copyKeyId {
            switch keyType {
            case .individual:
                """
                \(Self.awaitNoProgressBar)
                \(Self.findIndividualApiKeySection)
                \(Self.findIndividualKeyId)
                \(Self.styleIfPresent(.custom("keyId")))
                \(Self.scrollToIfPresent(.header))
                """
            case .team:
                """
                \(Self.findTeamNewApiKeySection)
                \(Self.styleIfPresent(.custom("keyId")))
                \(Self.scrollToIfPresent(.custom("keyId")))
                """
            }
        } else if self == .downloadKey {
            switch keyType {
            case .individual:
                """
                \(Self.awaitNoProgressBar)
                \(Self.findIndividualApiKeySection)
                \(Self.styleIfPresent(.downloadButton))
                \(Self.scrollToIfPresent(.downloadButton))
                """
            case .team:
                """
                \(Self.findTeamNewApiKeySection)
                \(Self.styleIfPresent(.downloadButton))
                \(Self.scrollToIfPresent(.downloadButton))
                """
            }
        } else {
            nil
        }
    }

    /// JavaScript that returns true if API key creation is allowed
    static var isIndividualApiKeyCreationAllowedScript: String {
        // The navigating from Users page to User Details page doesn't trigger a navigation event.
        // We have to wait for the sandbox link to disappear and a progressbar to appear.
        """
        while (document.querySelectorAll("a[href='/access/users/sandbox']").length > 0) {
            await new Promise(r => setTimeout(r, 200));
        }
        let navBar;
        const navBarSearchStart = performance.now();
        while (!(navBar = document.querySelector('#profile-nav')) && performance.now() - navBarSearchStart < 3000) {
            await new Promise(r => setTimeout(r, 200));
        }
        let progressBar;
        const progressBarSearchStart = performance.now();
        while (!(progressBar = document.querySelector('[role="progressbar"]')) && performance.now() - progressBarSearchStart < 3000) {
            await new Promise(r => setTimeout(r, 200));
        }
        \(awaitNoProgressBar)
        \(findIndividualApiKeySection)
        return !!header;
        """
    }

    /**
     JavaScript that returns true if team API key creation is allowed.

     - Parameter onApiPage: Boolean indicating if the current page is the API page.
     */
    static func isTeamApiKeyCreationAllowedScript(onApiPage: Bool) -> String {
        if onApiPage {
            """
            \(awaitNoProgressBar)
            const link = document.evaluate(
                '//ul[@role="navigation"]//a[contains(@href, "/access/integrations/api/individual-keys")]',
                document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null
            ).singleNodeValue;
            return !!link;
            """
        } else {
            """
            \(awaitNoProgressBar)
            const link = document.evaluate(
                '//div[@role="navigation"]//a[contains(@href, "/access/integrations/api")]',
                document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null
            ).singleNodeValue;
            return !!link;
            """
        }
    }

    private static let awaitNoProgressBar = """
    while (document.querySelectorAll('[role="progressbar"]').length > 0) {
        await new Promise(r => setTimeout(r, 200));
    }
    """

    private static let findIndividualApiKeySection = #"""
    const headerXPath = './/h3[@color="title" and normalize-space()="Individual API Key"]';
    const header = document.evaluate(headerXPath, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
    let containerDiv = null;
    let revokeButton = null;
    let downloadButton = null;
    let generateNewKeyButton = null;
    if (header) {
        containerDiv = document.evaluate(headerXPath + '/following-sibling::div[1]', document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
        if (containerDiv) {
            revokeButton = Array.from(containerDiv.querySelectorAll('button')).find(btn => btn.textContent.trim() === 'Revoke');
            downloadButton = Array.from(containerDiv.querySelectorAll('button')).find(btn => btn.textContent.trim() === 'Download API Key');
            generateNewKeyButton = Array.from(containerDiv.querySelectorAll('button')).find(btn => /Generate\s*(New\s*)?Key/i.test(btn.textContent));
        }
    }
    """#

    private static let findIndividualKeyId = """
    const keyId = document.evaluate(
        './/h3[@color="title" and normalize-space()="Individual API Key"]/following-sibling::div[1]//table[1]/tbody[1]/tr[1]/td[1]//p[1]',
        document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null
    ).singleNodeValue;
    """

    private static let findTeamIssuerId = """
    const issuerId = document.evaluate(
        './/span[normalize-space()="Issuer ID"]/following::span[@role="presentation"][1]',
        document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null
    ).singleNodeValue;
    """

    private static let findTeamNewApiKeySection = """
    const keyId = document.evaluate(
        './/button[normalize-space()="Download"]/ancestor::*[@role="row"]//p',
        document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null
    ).singleNodeValue;;
    const downloadButton = document.evaluate(
        './/button[normalize-space()="Download"]',
        document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null
    ).singleNodeValue;
    """

    /**
     JavaScript that scrolls to the specified element if it is present.

     - Parameter elementName: The name of the element to scroll to.
     */
    private static func scrollToIfPresent(_ elementName: ElementName) -> String {
        """
        if (\(elementName)) {
            \(elementName).scrollIntoView({
                behavior: 'smooth',
                block: 'center'
            });
        }
        """
    }

    /**
     JavaScript that styles the specified element if it is present.

     - Parameters:
        - elementName: The name of the element to style.
        - padding: The padding to apply (default is "8px").
        - border: Boolean indicating whether to apply a border (default is true).
     */
    private static func styleIfPresent(_ elementName: ElementName, padding: String = "8px", border: Bool = true) -> String {
        """
        if (\(elementName)) {
            const el = \(elementName);
            el.style.border = '\(border ? "4px solid red" : "none")';
            el.style.borderRadius = '\(border ? "12px" : "0px")';
            el.style.padding = '\(padding)';
        }
        """
    }

    /// Enumeration representing element names used in JavaScript.
    private enum ElementName: CustomStringConvertible {
        case header, revokeButton, downloadButton, generateNewKeyButton
        case custom(String)

        var description: String {
            switch self {
            case .header: "header"
            case .revokeButton: "revokeButton"
            case .downloadButton: "downloadButton"
            case .generateNewKeyButton: "generateNewKeyButton"
            case .custom(let name): name
            }
        }
    }
}
