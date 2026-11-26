import AuthenticationServices
import CryptoKit
import SwiftUI

private let bot = "MynineUzBot"

struct LoginView: View {
    @EnvironmentObject private var session: Session
    @Environment(\.openURL) private var openURL
    @State private var code = ""
    @State private var login = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var busy = false
    @State private var error: String?
    @FocusState private var codeFocused: Bool
    @StateObject private var google = GoogleSignIn()

    var body: some View {
        ZStack {
            GlassBackground(variant: 0)
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 10) {
                        Image("LogoMark").resizable().scaledToFill().frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        Text("mynine").font(.system(size: 22, weight: .heavy)).foregroundStyle(Mn.ink)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text(tr("login_title")).font(.system(size: 32, weight: .heavy)).foregroundStyle(Mn.ink).tracking(-0.8)
                        Text(tr("login_subtitle")).font(.system(size: 16)).foregroundStyle(Mn.muted)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 12) {
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            handleApple(result)
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 52)
                        .clipShape(Capsule())

                        SecondaryButton(title: tr("google_sign_in"), image: "GoogleLogo", enabled: !busy) {
                            run {
                                guard let token = try await google.idToken() else { throw CancellationError() }
                                session.signIn(try await API.shared.send(.post, "auth/google", body: ["id_token": token]))
                            }
                        }

                        divider(tr("or_telegram"))

                        Button {
                            openBot()
                            codeFocused = true
                        } label: {
                            Label(tr("get_code", bot), systemImage: "paperplane")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Mn.accentDark)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Mn.accentSoft, in: Capsule())
                        }

                        Text(tr("code_6")).font(.system(size: 13, weight: .semibold)).foregroundStyle(Mn.muted).frame(maxWidth: .infinity, alignment: .leading)
                        OtpField(code: $code, focused: $codeFocused) { full in
                            run { session.signIn(try await API.shared.send(.post, "auth/telegram", body: ["code": full])) }
                        }

                        PrimaryButton(title: tr("sign_in"), loading: busy && !showPassword, enabled: code.count == 6) {
                            run { session.signIn(try await API.shared.send(.post, "auth/telegram", body: ["code": code])) }
                        }

                        if !showPassword {
                            Button(tr("with_password")) { withAnimation { showPassword = true } }
                                .font(.system(size: 14, weight: .semibold)).foregroundStyle(Mn.accent).padding(.top, 4)
                        } else {
                            divider(tr("login_password"))
                            field(tr("email_or_login"), text: $login).textContentType(.username).keyboardType(.emailAddress)
                            SecureField(tr("password"), text: $password)
                                .textContentType(.password)
                                .padding(.horizontal, 16).frame(height: 52)
                                .background(Mn.surface, in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Mn.fieldBorder))
                            SecondaryButton(title: tr("sign_in_password"), systemImage: "lock", enabled: !busy && !login.isEmpty && !password.isEmpty) {
                                run {
                                    session.signIn(try await API.shared.send(.post, "auth/password", body: ["login": login.trimmingCharacters(in: .whitespaces), "password": password]))
                                }
                            }
                        }

                        if let error { Text(error).font(.system(size: 14)).foregroundStyle(Mn.red).frame(maxWidth: .infinity, alignment: .leading) }
                    }
                    .padding(20)
                    .glass(radius: 28)

                    Text(tr("login_footer"))
                        .font(.system(size: 13)).foregroundStyle(Mn.subtle).multilineTextAlignment(.center).frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24).padding(.vertical, 20)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func divider(_ label: String) -> some View {
        HStack(spacing: 12) {
            Rectangle().fill(Mn.ink.opacity(0.12)).frame(height: 1)
            Text(label).font(.system(size: 13, weight: .medium)).foregroundStyle(Mn.subtle).fixedSize()
            Rectangle().fill(Mn.ink.opacity(0.12)).frame(height: 1)
        }
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.horizontal, 16).frame(height: 52)
            .background(Mn.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Mn.fieldBorder))
    }

    private func run(_ block: @escaping () async throws -> Void) {
        guard !busy else { return }
        busy = true
        error = nil
        Task {
            do { try await block() } catch is CancellationError {} catch { self.error = error.localizedDescription }
            busy = false
        }
    }

    private func openBot() {
        let tg = URL(string: "tg://resolve?domain=\(bot)&start=app")!
        if UIApplication.shared.canOpenURL(tg) { openURL(tg) } else { openURL(URL(string: "https://t.me/\(bot)?start=app")!) }
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let e):
            if (e as? ASAuthorizationError)?.code != .canceled { error = tr("apple_failed") }
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken, let token = String(data: tokenData, encoding: .utf8) else {
                error = tr("apple_failed")
                return
            }
            let name = [credential.fullName?.givenName, credential.fullName?.familyName].compactMap { $0 }.joined(separator: " ")
            run {
                session.signIn(try await API.shared.send(.post, "auth/apple", body: ["identity_token": token, "name": name]))
            }
        }
    }
}

/// Six boxes over one hidden text field; submits when the sixth digit is typed.
struct OtpField: View {
    @Binding var code: String
    var focused: FocusState<Bool>.Binding
    let onComplete: (String) -> Void

    var body: some View {
        ZStack {
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused(focused)
                .opacity(0.02)
                .onChange(of: code) { _, value in
                    let digits = String(value.filter(\.isNumber).prefix(6))
                    if digits != value { code = digits }
                    if digits.count == 6 { onComplete(digits) }
                }
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { i in
                    let chars = Array(code)
                    let ch = i < chars.count ? String(chars[i]) : ""
                    Text(ch)
                        .font(.system(size: 22, weight: .bold)).foregroundStyle(Mn.ink)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(Mn.surface, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(!ch.isEmpty || i == chars.count ? Mn.accent : Mn.fieldBorder, lineWidth: 1.5))
                }
            }
            .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture { focused.wrappedValue = true }
    }
}

/// Google sign-in without an SDK: OAuth 2.0 authorization code + PKCE in ASWebAuthenticationSession
/// (iOS OAuth client of the "younine" Cloud project, Info.plist GIDClientID), then the code is exchanged for
/// an ID token that the server checks (GOOGLE_MOBILE_CLIENT_IDS).
@MainActor
final class GoogleSignIn: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    private var session: ASWebAuthenticationSession?

    private var clientId: String { Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String ?? "" }
    private var scheme: String { "com.googleusercontent.apps." + clientId.replacingOccurrences(of: ".apps.googleusercontent.com", with: "") }
    private var redirect: String { scheme + ":/oauth2redirect" }

    func idToken() async throws -> String? {
        let verifier = Self.random(64)
        let challenge = Data(SHA256.hash(data: Data(verifier.utf8))).base64URL
        let state = Self.random(24)
        var url = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        url.queryItems = [
            .init(name: "client_id", value: clientId),
            .init(name: "redirect_uri", value: redirect),
            .init(name: "response_type", value: "code"),
            .init(name: "scope", value: "openid email profile"),
            .init(name: "code_challenge", value: challenge),
            .init(name: "code_challenge_method", value: "S256"),
            .init(name: "state", value: state),
            .init(name: "prompt", value: "select_account"),
        ]

        let callback: URL? = try await withCheckedThrowingContinuation { cont in
            let s = ASWebAuthenticationSession(url: url.url!, callbackURLScheme: scheme) { url, error in
                if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
                    cont.resume(returning: nil)
                } else if let error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: url)
                }
            }
            s.presentationContextProvider = self
            s.prefersEphemeralWebBrowserSession = false
            session = s
            s.start()
        }
        guard let callback, let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems,
              items.first(where: { $0.name == "state" })?.value == state,
              let code = items.first(where: { $0.name == "code" })?.value else { return nil }

        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let form = ["code": code, "client_id": clientId, "redirect_uri": redirect, "grant_type": "authorization_code", "code_verifier": verifier]
        request.httpBody = form.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "")" }.joined(separator: "&").data(using: .utf8)
        let (data, _) = try await URLSession.shared.data(for: request)
        struct TokenResponse: Decodable { let id_token: String? }
        guard let token = try? JSONDecoder().decode(TokenResponse.self, from: data).id_token else {
            throw APIError(status: 0, code: "google", message: tr("google_failed"))
        }
        return token
    }

    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first ?? ASPresentationAnchor()
        }
    }

    private static func random(_ length: Int) -> String {
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return String((0..<length).map { _ in chars.randomElement()! })
    }
}

private extension Data {
    var base64URL: String {
        base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
}
