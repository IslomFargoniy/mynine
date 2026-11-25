import AVFoundation
import Foundation

enum ExamPhase: Equatable { case loading, intro, running, submitting, done, error }

struct NavQuestion: Identifiable {
    let partIndex: Int
    let question: QuestionPayload
    var id: Int { question.id }
    var label: String {
        let n = question.numberCount ?? 1
        return n > 1 ? "\(question.number)–\(question.number + n - 1)" : "\(question.number)"
    }
}

/// Exam flow, the same as the Android app: modules in order (Listening → Reading → Writing), server-timed,
/// answers queued on the device, Listening recording played once (a late start extends the module).
@MainActor
final class ExamViewModel: ObservableObject {
    let attemptId: Int

    @Published var phase: ExamPhase = .loading
    @Published var attempt: AttemptState?
    @Published var module: ExamModule?
    @Published var moduleIndex = 0
    @Published var parts: [LoadedPart] = []
    @Published var partIndex = 0
    @Published var remaining: TimeInterval = 0
    @Published var answers: [Int: SavedAnswer] = [:]
    @Published var flagged: Set<Int> = []
    @Published var error: String?
    @Published var offline = false
    @Published var autoSubmitted = false
    @Published var volume: Float = 1 { didSet { player?.volume = volume } }
    @Published var audioPlaying = false

    private let queue: AnswerQueue
    private var serverOffset: TimeInterval = 0
    private var finishedAt = Date()
    private var ticker: Task<Void, Never>?
    private var flusher: Task<Void, Never>?
    private var player: AVPlayer?
    private var audioReported = false
    private var audioStartedAt = Date()
    private var knownLag = 0

    init(attemptId: Int) {
        self.attemptId = attemptId
        queue = AnswerQueue(attemptId: attemptId)
    }

    var part: LoadedPart? { parts.indices.contains(partIndex) ? parts[partIndex] : nil }

    var navQuestions: [NavQuestion] {
        parts.enumerated().flatMap { i, p in p.payload.sections.flatMap { $0.questions.map { NavQuestion(partIndex: i, question: $0) } } }
    }

    func answered(_ id: Int) -> Bool {
        guard let a = answers[id] else { return false }
        return !(a.text ?? "").trimmingCharacters(in: .whitespaces).isEmpty || !a.optionIds.isEmpty
    }

    // MARK: flow

    func load() {
        phase = .loading
        error = nil
        Task {
            do {
                let env: AttemptEnvelope = try await API.shared.send(.get, "attempts/\(attemptId)")
                sync(env.attempt.serverTime)
                await queue.flush()
                try await route(env.attempt)
            } catch {
                self.error = error.localizedDescription
                phase = .error
            }
        }
    }

    private func route(_ attempt: AttemptState) async throws {
        self.attempt = attempt
        if attempt.status == "completed" {
            await queue.clear()
            phase = .done
            return
        }
        guard let index = attempt.modules.firstIndex(where: { $0.status != "submitted" }) else {
            try await finishAttempt()
            return
        }
        let m = attempt.modules[index]
        module = m
        moduleIndex = index
        parts = []
        partIndex = 0
        autoSubmitted = false
        if m.status == "in_progress", let end = m.finishedAt {
            try await enter(m, startedAt: m.startedAt, finishedAt: end, fresh: false, knownLag: m.audioLagSeconds ?? 0)
        } else {
            phase = .intro
        }
    }

    func startModule() {
        guard let m = module else { return }
        phase = .loading
        Task {
            do {
                let timer: ModuleTimer = try await API.shared.send(.post, "attempts/\(attemptId)/modules/\(m.typeId)/start")
                sync(timer.serverTime)
                try await enter(m, startedAt: timer.startedAt, finishedAt: timer.finishedAt ?? ServerTime.now(), fresh: true, knownLag: timer.audioLagSeconds ?? 0)
            } catch {
                self.error = error.localizedDescription
                phase = .intro
            }
        }
    }

    private func enter(_ m: ExamModule, startedAt: String?, finishedAt end: String, fresh: Bool, knownLag: Int) async throws {
        finishedAt = ServerTime.parse(end) ?? Date()
        var loaded: [LoadedPart] = []
        for ref in m.parts.sorted(by: { ($0.order ?? 0) < ($1.order ?? 0) }) {
            let raw = try await API.shared.data(.get, "attempts/\(attemptId)/parts/\(ref.id)")
            let payload = try API.shared.decoder.decode(PartPayload.self, from: raw)
            loaded.append(LoadedPart(payload: payload, raw: raw))
        }
        var map: [Int: SavedAnswer] = [:]
        for p in loaded { for s in p.payload.sections { for q in s.questions { map[q.id] = q.answer ?? SavedAnswer() } } }
        // Answers the server has not confirmed yet win over its copy.
        for item in await queue.pendingAnswers() {
            let old = map[item.questionId] ?? SavedAnswer()
            map[item.questionId] = SavedAnswer(text: item.text ?? (item.optionIds != nil ? old.text : nil), optionIds: item.optionIds ?? old.optionIds)
        }
        parts = loaded
        answers = map
        module = m
        remaining = max(0, finishedAt.timeIntervalSince(now()))
        phase = .running
        startTicker()
        startFlusher()
        if m.type == "listening" { startAudio(m, startedAt: startedAt, fresh: fresh, knownLag: knownLag) }
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.remaining = max(0, self.finishedAt.timeIntervalSince(self.now()))
                self.checkAudioLag()
                if self.remaining <= 0, self.phase == .running {
                    self.submitModule(auto: true)
                    return
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }

    private func startFlusher() {
        flusher?.cancel()
        flusher = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.queue.flush()
                self.offline = await self.queue.offline
                try? await Task.sleep(nanoseconds: self.offline ? 5_000_000_000 : 1_500_000_000)
            }
        }
    }

    func selectPart(_ i: Int) { if parts.indices.contains(i) { partIndex = i } }

    func onAnswer(partId: Int, questionId: Int, text: String?, optionIds: [Int]?, hasText: Bool, hasOptions: Bool) {
        guard phase == .running else { return }
        let old = answers[questionId] ?? SavedAnswer()
        answers[questionId] = SavedAnswer(text: hasText ? text : old.text, optionIds: hasOptions ? (optionIds ?? []) : old.optionIds)
        Task { await queue.put(partId: partId, questionId: questionId, text: hasText ? text : nil, optionIds: hasOptions ? (optionIds ?? []) : nil) }
    }

    func toggleFlag(_ id: Int) {
        if flagged.contains(id) { flagged.remove(id) } else { flagged.insert(id) }
    }

    func submitModule(auto: Bool = false) {
        guard let m = module, phase != .submitting else { return }
        phase = .submitting
        autoSubmitted = auto
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000) // the page's debounced text answers arrive first
            for _ in 0..<4 { if await queue.flush() { break }; try? await Task.sleep(nanoseconds: 1_500_000_000) }
            stopAudio()
            ticker?.cancel()
            do {
                _ = try await API.shared.data(.post, "attempts/\(attemptId)/modules/\(m.typeId)/submit")
            } catch let e as APIError where e.offline {
                error = "Internet yo'q: modul yakunlanmadi. Aloqa tiklangach yana bosing."
                phase = .running
                startTicker()
                return
            } catch {}
            do {
                let env: AttemptEnvelope = try await API.shared.send(.get, "attempts/\(attemptId)")
                sync(env.attempt.serverTime)
                try await route(env.attempt)
            } catch {
                self.error = error.localizedDescription
                phase = .error
            }
        }
    }

    private func finishAttempt() async throws {
        phase = .submitting
        for _ in 0..<3 { if await queue.flush() { break }; try? await Task.sleep(nanoseconds: 1_500_000_000) }
        _ = try await API.shared.data(.post, "attempts/\(attemptId)/submit")
        await queue.clear()
        phase = .done
    }

    /// App back in the foreground: re-sync the clock; the module may have ended meanwhile.
    func onForeground() {
        guard phase == .running else { return }
        Task {
            guard let env: AttemptEnvelope = try? await API.shared.send(.get, "attempts/\(attemptId)") else { return }
            sync(env.attempt.serverTime)
            let m = env.attempt.modules.indices.contains(moduleIndex) ? env.attempt.modules[moduleIndex] : nil
            if m?.status == "submitted" || env.attempt.status == "completed" {
                stopAudio()
                ticker?.cancel()
                try? await route(env.attempt)
            } else if let end = ServerTime.parse(m?.finishedAt) {
                finishedAt = end
            }
        }
    }

    func stop() {
        ticker?.cancel()
        flusher?.cancel()
        stopAudio()
    }

    // MARK: render config for the exam room page

    func renderConfig(view: String, layout: String) -> String? {
        guard let part, var json = (try? JSONSerialization.jsonObject(with: part.raw)) as? [String: Any] else { return nil }
        json.removeValue(forKey: "server_time")
        var answerMap: [String: Any] = [:]
        for s in part.payload.sections {
            for q in s.questions {
                if let a = answers[q.id] { answerMap[String(q.id)] = ["text": a.text.map { $0 as Any } ?? NSNull(), "option_ids": a.optionIds] }
            }
        }
        var config: [String: Any] = [
            "part": json,
            "answers": answerMap,
            "flagged": Array(flagged),
            "locked": phase != .running,
            "view": view,
            "layout": layout,
            "baseUrl": API.shared.baseURL.absoluteString,
        ]
        if let marks = UserDefaults.standard.data(forKey: marksKey(part.payload.id)), let obj = try? JSONSerialization.jsonObject(with: marks) {
            config["marks"] = obj
        }
        guard let data = try? JSONSerialization.data(withJSONObject: config) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func marksKey(_ partId: Int) -> String { "marks-\(attemptId)-\(partId)" }

    /// Highlights and notes of a part (exam room page format), kept on the device like the desktop app.
    func saveMarks(partId: Int, json: Data) { UserDefaults.standard.set(json, forKey: marksKey(partId)) }

    // MARK: audio (Listening plays once, never paused)

    private func startAudio(_ m: ExamModule, startedAt: String?, fresh: Bool, knownLag: Int) {
        stopAudio()
        var urls: [URL] = []
        if let a = m.audio, let u = URL(string: a.url) { urls = [u] } else {
            urls = parts.filter { $0.payload.audioKey != nil }
                .compactMap { API.shared.url("attempts/\(attemptId)/audio/part/\($0.payload.id)") }
        }
        guard !urls.isEmpty else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        let headers = ["Authorization": "Bearer \(API.shared.token ?? "")"]
        let items = urls.map { AVPlayerItem(asset: AVURLAsset(url: $0, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])) }
        let p: AVPlayer = items.count > 1 ? AVQueuePlayer(items: items) : AVPlayer(playerItem: items[0])
        p.volume = volume
        audioStartedAt = ServerTime.parse(startedAt) ?? now()
        audioReported = urls.count > 1
        self.knownLag = knownLag
        // A new module always plays from 0:00; a resumed one continues past the lag already added to the clock.
        if !fresh, urls.count == 1 {
            let position = now().timeIntervalSince(audioStartedAt) - Double(knownLag)
            if position > 1.5 { p.seek(to: CMTime(seconds: position, preferredTimescale: 600)) }
        }
        p.play()
        player = p
    }

    /// The recording started later than the module clock (parts loading, buffering, app closed): the module ends
    /// that much later, like the desktop app (the total is sent; the server never shortens).
    private func checkAudioLag() {
        guard let p = player else { return }
        audioPlaying = p.timeControlStatus == .playing
        guard !audioReported, p.timeControlStatus == .playing, let m = module else { return }
        audioReported = true
        let lag = Int(now().timeIntervalSince(audioStartedAt) - p.currentTime().seconds)
        guard lag > knownLag else { return }
        Task {
            struct Body: Encodable { let lagSeconds: Int }
            if let timer: ModuleTimer = try? await API.shared.send(.post, "attempts/\(attemptId)/modules/\(m.typeId)/audio-lag", body: Body(lagSeconds: lag)) {
                sync(timer.serverTime)
                if let end = ServerTime.parse(timer.finishedAt) { finishedAt = end }
            }
        }
    }

    private func stopAudio() {
        player?.pause()
        player = nil
        audioPlaying = false
    }

    // MARK: clock

    private func sync(_ serverTime: String?) {
        if let t = ServerTime.parse(serverTime) { serverOffset = t.timeIntervalSinceNow }
    }

    private func now() -> Date { Date().addingTimeInterval(serverOffset) }
}
