//
//  signInWithApple.swift
//  Trigger
//
//  Created by Matan Cohen on 10/11/2025.
//

import SwiftUI
import AuthenticationServices

struct SignInWithAppleView: View {
    @EnvironmentObject private var authStore: AuthStore

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("green_L1"), Color("green_L2")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Title with emphasized "Trigger"
                HStack(spacing: 8) {
                    Text("welcome to")
                        .font(.system(.largeTitle, design: .rounded).bold())
                        .foregroundStyle(.primary)

                    Text("Trigger")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundColor(Color("green_L4"))
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 4)
                }
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

                // Sign in with Apple button
                SignInWithAppleButtonView(
                    onRequest: { request in
                        // Configure requested scopes as needed
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let auth):
                            handleAuthorization(auth)
                        case .failure(let error):
                            handleError(error)
                        }
                    }
                )
                .frame(height: 52)
                .padding(.top, 8)
                .padding(.horizontal, 0)
            }
            .padding(.horizontal, 20)
        }
    }

    private func handleAuthorization(_ auth: ASAuthorization) {
        if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
            // Persist the stable user identifier that Apple provides
            let userID = credential.user
            authStore.setAuthenticated(userID: userID)

            // Persist full name if provided (only available on first sign-in)
            authStore.setFullNameIfAvailable(credential.fullName)
        }
    }

    private func handleError(_ error: Error) {
        // TODO: Present an error UI or log as appropriate
        // print("Sign in with Apple failed:", error.localizedDescription)
    }
}

private struct SignInWithAppleButtonView: View {
    var onRequest: (ASAuthorizationAppleIDRequest) -> Void
    var onCompletion: (Result<ASAuthorization, Error>) -> Void

    var body: some View {
        SignInWithAppleButtonRepresentable(onRequest: onRequest, onCompletion: onCompletion)
            .signInWithAppleButtonStyle(.whiteOutline) // Adjust style to fit your design
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
            .accessibilityLabel("Sign up with Apple")
    }
}

private struct SignInWithAppleButtonRepresentable: UIViewRepresentable {
    var onRequest: (ASAuthorizationAppleIDRequest) -> Void
    var onCompletion: (Result<ASAuthorization, Error>) -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signUp, style: .white)
        button.addTarget(context.coordinator, action: #selector(Coordinator.didTapButton), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        // No dynamic updates needed right now
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onRequest: onRequest, onCompletion: onCompletion)
    }

    final class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        private let onRequest: (ASAuthorizationAppleIDRequest) -> Void
        private let onCompletion: (Result<ASAuthorization, Error>) -> Void

        init(onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void,
             onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void) {
            self.onRequest = onRequest
            self.onCompletion = onCompletion
        }

        @objc func didTapButton() {
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            onRequest(request)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        // MARK: - ASAuthorizationControllerDelegate

        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            onCompletion(.success(authorization))
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            onCompletion(.failure(error))
        }

        // MARK: - Presentation Context

        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            // Prefer the key window if available
            if let keyWindow = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }) {
                return keyWindow
            }

            // Otherwise, use the first window in the first window scene; if none, create a transient one bound to that scene.
            if let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first {

                if let anyWindow = windowScene.windows.first {
                    return anyWindow
                }

                // Create a transient window attached to the found scene
                let transient = UIWindow(windowScene: windowScene)
                return transient
            }

            // As a last resort, avoid deprecated UIWindow() init by attempting to find any window from any scene
            assertionFailure("No connected UIWindowScene available for presentation.")
            if let anyWindow = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first {
                return anyWindow
            }

            // If truly nothing is available, create a new window only when we have a scene (should be extremely rare)
            // Returning a new, unattached UIWindow() would use a deprecated initializer, so we avoid it.
            fatalError("Unable to obtain a presentation anchor for ASAuthorizationController.")
        }
    }
}

#Preview {
    SignInWithAppleView()
        .environmentObject(AuthStore())
}
