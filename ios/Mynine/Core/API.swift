import Foundation

// Student API (/api/v1/student) — docs/mobile/API.md. Same contract as the Android app.

struct User: Codable, Equatable {
    let id: Int
    var name: String
    var email: String?
    var username: String?
    var avatar: String?
    var telegramConnected: Bool?
    var googleConnected: Bool?
    var appleConnected: Bool?
}

struct AuthResponse: Decodable { let token: String; let user: User }
struct UserResponse: Decodable { let user: User }
struct ErrorBody: Decodable { let message: String?; let code: String? }

struct Folder: Decodable, Hashable { let id: Int; let name: String }

struct TestModule: Decodable, Hashable {
    let typeId: Int
    let type: String
    let title: String
    var durationSeconds: Int?
    var partsCount: Int?
    var questionsCount: Int?
}

struct TestItem: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    var comment: String?
    var variant: String?
    var folder: Folder?
    var modules: [TestModule]
    var attemptsCount: Int?
    var inProgressAttemptId: Int?
    var lastFinishedAttemptId: Int?
}

struct PageMeta: Decodable { var currentPage: Int?; var lastPage: Int?; var total: Int? }
struct TestsResponse: Decodable { let data: [TestItem]; var meta: PageMeta? }
struct TestResponse: Decodable { let test: TestItem }

struct Ref: Decodable, Hashable { let id: Int; var name: String? }
struct ModuleAudio: Decodable { let url: String; var durationSeconds: Int? }
struct PartRef: Decodable { let id: Int; var name: String?; var order: Int?; var questionCount: Int?; var firstQuestionNumber: Int? }

struct ExamModule: Decodable {
    let typeId: Int
    let type: String
    let title: String
    var durationSeconds: Int?
    var status: String
    var startedAt: String?
    var finishedAt: String?
    var audioLagSeconds: Int?
    var audio: ModuleAudio?
    var parts: [PartRef]
}

struct AttemptState: Decodable {
    let id: Int
    let test: Ref
    var module: String?
    let status: String
    var paused: Bool?
    var modules: [ExamModule]
    var serverTime: String?
}

struct AttemptEnvelope: Decodable { let attempt: AttemptState; var resumed: Bool? }

struct ModuleTimer: Decodable {
    let typeId: Int
    let status: String
    var startedAt: String?
    var finishedAt: String?
    var audioLagSeconds: Int?
    var serverTime: String?
}

struct Bands: Decodable, Hashable {
    var overall: Double?
    var listening: Double?
    var reading: Double?
    var writing: Double?
    var writingPending: Bool?
}

struct AttemptSummary: Decodable, Identifiable, Hashable {
    let id: Int
    let test: Ref
    var module: String?
    let status: String
    var startedAt: String?
    var finishedAt: String?
    var modules: [String]?
    var bands: Bands?
}

struct AttemptsResponse: Decodable { let data: [AttemptSummary]; var meta: PageMeta? }

struct SavedAnswer: Codable, Equatable {
    var text: String?
    var optionIds: [Int]

    init(text: String? = nil, optionIds: [Int] = []) { self.text = text; self.optionIds = optionIds }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        text = try c.decodeIfPresent(String.self, forKey: .text)
        optionIds = (try? c.decodeIfPresent([Int].self, forKey: .optionIds)) ?? []
    }
}

struct QuestionPayload: Decodable { let id: Int; let number: Int; var numberCount: Int?; var answer: SavedAnswer? }
struct SectionPayload: Decodable { let id: Int; var questionType: String?; var questions: [QuestionPayload] }
struct PartPayload: Decodable { let id: Int; let type: String; let typeId: Int; var name: String?; var order: Int?; var html: String?; var audioKey: String?; var sections: [SectionPayload] }

/// A part as the exam room page needs it (raw JSON) plus the fields the app reads.
struct LoadedPart { let payload: PartPayload; let raw: Data }

struct AnswerItem: Codable {
    let clientUuid: String
    let partId: Int
    let questionId: Int
    var text: String?
    var optionIds: [Int]?
    let changedAt: String
    let seq: Int
}

struct AnswerResult: Decodable { let clientUuid: String; let status: String; var reason: String? }
struct AnswersResponse: Decodable { let results: [AnswerResult] }

struct FullBands: Decodable {
    var overall: Double?
    var listening: Double?
    var reading: Double?
    var writing: Double?
    var writingPending: Bool?
}

struct ReviewQuestion: Decodable, Identifiable {
    var id: Int { questionId }
    let questionId: Int
    let number: Int
    var numberCount: Int?
    var yourAnswer: String?
    var correctAnswer: String?
    var points: Int?
    var maxPoints: Int?
    var isCorrect: Bool
}

struct EssayReview: Decodable, Identifiable {
    var id: Int { questionId }
    let questionId: Int
    let task: Int
    var answer: String?
    var words: Int?
    var band: Double?
    var feedback: String?
}

struct ResultModule: Decodable, Identifiable {
    var id: String { type }
    let type: String
    let typeId: Int
    let title: String
    var band: Double?
    var correct: Double?
    var questions: [ReviewQuestion]
    var essays: [EssayReview]
}

struct ResultResponse: Decodable { let attempt: AttemptSummary; let bands: FullBands; let modules: [ResultModule] }

// MARK: - Client

struct APIError: LocalizedError {
    let status: Int
    let code: String?
    let message: String

    var offline: Bool { status == 0 }

    var errorDescription: String? {
        switch code {
        case "invalid_code": return "Kod noto'g'ri yoki muddati o'tgan. Botdan yangi kod oling."
        case "invalid_credentials": return "Login yoki parol noto'g'ri."
        case "staff_account": return "Bu xodim akkaunti. Xodimlar mynine.uz saytidan foydalanadi."
        case "account_suspended": return "Akkaunt bloklangan."
        case "too_many_requests": return "Juda ko'p urinish. Bir daqiqadan keyin qayta urinib ko'ring."
        case "module_locked": return "Avval oldingi modulni yakunlang."
        default: return message
        }
    }
}

enum HTTPMethod: String { case get = "GET", post = "POST", patch = "PATCH", delete = "DELETE" }

final class API: @unchecked Sendable {
    static let shared = API()

    #if DEBUG
    let baseURL = URL(string: ProcessInfo.processInfo.environment["MYNINE_BASE_URL"] ?? "https://mynine.uz")!
    #else
    let baseURL = URL(string: "https://mynine.uz")!
    #endif

    /// Set by Session; read on every request.
    var token: String?
    /// Called on 401 with a token: the session is gone.
    var onUnauthorized: (() -> Void)?

    let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 30
        c.waitsForConnectivity = false
        return URLSession(configuration: c)
    }()

    var appVersion: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0" }

    func url(_ path: String) -> URL { baseURL.appendingPathComponent("api/v1/student/" + path) }

    func data(_ method: HTTPMethod, _ path: String, query: [String: String?] = [:], body: Encodable? = nil) async throws -> Data {
        var components = URLComponents(url: url(path), resolvingAgainstBaseURL: false)!
        let items = query.compactMap { k, v in v.map { URLQueryItem(name: k, value: $0) } }
        if !items.isEmpty { components.queryItems = items }
        var request = URLRequest(url: components.url!)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("ios", forHTTPHeaderField: "X-Platform")
        request.setValue(appVersion, forHTTPHeaderField: "X-App-Version")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError(status: 0, code: "offline", message: "Internet aloqasi yo'q. Qayta urinib ko'ring.")
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            if status == 401, token != nil { onUnauthorized?() }
            let parsed = try? decoder.decode(ErrorBody.self, from: data)
            throw APIError(status: status, code: parsed?.code, message: parsed?.message ?? "Server xatosi (\(status))")
        }
        return data
    }

    func send<T: Decodable>(_ method: HTTPMethod, _ path: String, query: [String: String?] = [:], body: Encodable? = nil) async throws -> T {
        let data = try await data(method, path, query: query, body: body)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError(status: 200, code: "decode", message: "Javobni o'qib bo'lmadi.")
        }
    }
}

private struct AnyEncodable: Encodable {
    let value: Encodable
    init(_ value: Encodable) { self.value = value }
    func encode(to encoder: Encoder) throws { try value.encode(to: encoder) }
}

struct EmptyResponse: Decodable {}

// MARK: - Time

enum ServerTime {
    static func parse(_ iso: String?) -> Date? {
        guard let iso else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: iso) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: iso)
    }

    static func now() -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: Date())
    }
}
