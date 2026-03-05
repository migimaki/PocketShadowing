//
//  AppleSignInCoordinator.swift
//  PocketShadowing
//

import AuthenticationServices

@MainActor
class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate,
                               ASAuthorizationControllerPresentationContextProviding {

    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

    static func signIn() async throws -> ASAuthorizationAppleIDCredential {
        let coordinator = AppleSignInCoordinator()
        return try await coordinator.performSignIn()
    }

    private func performSignIn() async throws -> ASAuthorizationAppleIDCredential {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.email, .fullName]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            Task { @MainActor in
                continuation?.resume(returning: credential)
            }
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithError error: Error) {
        Task { @MainActor in
            continuation?.resume(throwing: error)
        }
    }

    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }
}
