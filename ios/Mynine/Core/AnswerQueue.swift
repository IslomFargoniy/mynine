import Foundation

/// Answers of one attempt waiting for the server. Every change is written to Application Support first
/// (survives a crash, a restart or no internet) and sent in idempotent batches (client_uuid + per-question seq,
/// the server keeps the newest). Same contract as the Android and desktop queues.
actor AnswerQueue {
    private let attemptId: Int
    private var pending: [Int: AnswerItem] = [:] // questionId -> newest unsent item
    private var seqs: [Int: Int] = [:]
    private var flushing = false
    private(set) var offline = false

    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("answers", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("attempt-\(attemptId).json")
    }

    private struct Stored: Codable { var pending: [AnswerItem]; var seqs: [Int: Int] }

    init(attemptId: Int) {
        self.attemptId = attemptId
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("answers", isDirectory: true)
        if let data = try? Data(contentsOf: dir.appendingPathComponent("attempt-\(attemptId).json")),
           let stored = try? JSONDecoder().decode(Stored.self, from: data) {
            for item in stored.pending { pending[item.questionId] = item }
            seqs = stored.seqs
        }
    }

    var count: Int { pending.count }

    func pendingAnswers() -> [AnswerItem] { Array(pending.values) }

    func put(partId: Int, questionId: Int, text: String?, optionIds: [Int]?) {
        // Monotonic across reinstalls too: tenths of a second since 2026-01-01, never below the last one + 1.
        let clock = max(0, Int(Date().timeIntervalSince1970 * 10) - 17_672_256_000)
        let seq = max((seqs[questionId] ?? 0) + 1, min(clock, Int(Int32.max)))
        seqs[questionId] = seq
        pending[questionId] = AnswerItem(
            clientUuid: UUID().uuidString,
            partId: partId,
            questionId: questionId,
            text: text,
            optionIds: optionIds,
            changedAt: ServerTime.now(),
            seq: seq
        )
        persist()
    }

    /// Sends everything pending; returns true when nothing is left.
    @discardableResult
    func flush() async -> Bool {
        if flushing { return pending.isEmpty }
        let batch = Array(pending.values.prefix(200))
        if batch.isEmpty { return true }
        flushing = true
        defer { flushing = false }
        struct Body: Encodable { let answers: [AnswerItem] }
        do {
            let response: AnswersResponse = try await API.shared.send(.post, "attempts/\(attemptId)/answers", body: Body(answers: batch))
            offline = false
            let done = Set(response.results.filter { $0.status != "deferred" }.map(\.clientUuid))
            // Keep an item that changed again while the batch was in flight (its uuid differs).
            pending = pending.filter { !done.contains($0.value.clientUuid) }
            persist()
        } catch let error as APIError {
            offline = error.offline
            if error.code == "attempt_finished" { pending = [:]; persist() }
        } catch {}
        return pending.isEmpty
    }

    func clear() {
        pending = [:]
        seqs = [:]
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func persist() {
        let stored = Stored(pending: Array(pending.values), seqs: seqs)
        if let data = try? JSONEncoder().encode(stored) { try? data.write(to: fileURL, options: .atomic) }
    }
}
