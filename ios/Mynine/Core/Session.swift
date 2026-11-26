import Foundation
import Security

/// Signed-in student: API token in the Keychain, the cached profile in UserDefaults.
@MainActor
final class Session: ObservableObject {
    static let shared = Session()

    @Published private(set) var user: User?

    private let service = "uz.mynine.app.session"

    private init() {
        API.shared.token = Keychain.read(service: service, account: "token")
        if API.shared.token != nil, let data = UserDefaults.standard.data(forKey: "session.user") {
            user = try? JSONDecoder().decode(User.self, from: data)
        }
        if user == nil { API.shared.token = nil }
        ApiCache.userId = user?.id
        API.shared.onUnauthorized = { [weak self] in
            Task { @MainActor in self?.clear() }
        }
    }

    var signedIn: Bool { user != nil && API.shared.token != nil }

    func signIn(_ auth: AuthResponse) {
        Keychain.write(auth.token, service: service, account: "token")
        API.shared.token = auth.token
        update(auth.user)
    }

    func update(_ user: User) {
        UserDefaults.standard.set(try? JSONEncoder().encode(user), forKey: "session.user")
        ApiCache.userId = user.id
        self.user = user
    }

    func clear() {
        Keychain.delete(service: service, account: "token")
        UserDefaults.standard.removeObject(forKey: "session.user")
        API.shared.token = nil
        ApiCache.clear()
        ApiCache.userId = nil
        user = nil
    }
}

enum Keychain {
    static func read(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var out: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &out) == errSecSuccess, let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func write(_ value: String, service: String, account: String) {
        delete(service: service, account: account)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: Data(value.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
