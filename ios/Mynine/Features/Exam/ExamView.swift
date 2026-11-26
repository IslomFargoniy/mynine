import SwiftUI
import WebKit

/// Holds the WKWebView so the SwiftUI view can call into the exam room page.
@MainActor
final class ExamPage: ObservableObject {
    weak var webView: WKWebView?
    @Published var loaded = false
    @Published var hasPassage: [Int: Bool] = [:]

    func js(_ script: String) { webView?.evaluateJavaScript("window.ExamRoom && (\(script))", completionHandler: nil) }
}

/// The page shows its own Highlight · Note · Clear toolbar; the system edit menu (Copy, Look Up, Share) is removed.
final class ExamWKWebView: WKWebView {
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        for menu: UIMenu.Identifier in [.standardEdit, .lookup, .share, .learn, .find, .replace, .speech, .format, .textStyle, .writingDirection] {
            builder.remove(menu: menu)
        }
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool { false }
}

struct ExamWebView: UIViewRepresentable {
    let page: ExamPage
    let onMessage: (String, [String: Any]) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onMessage: onMessage) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "bridge")
        config.allowsInlineMediaPlayback = true
        let web = ExamWKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.isOpaque = false
        web.backgroundColor = .white
        web.scrollView.bounces = false
        web.scrollView.contentInsetAdjustmentBehavior = .never
        #if DEBUG
        if #available(iOS 16.4, *) { web.isInspectable = true }
        #endif
        if let dir = Bundle.main.url(forResource: "exam-room", withExtension: nil) {
            web.loadFileURL(dir.appendingPathComponent("index.html"), allowingReadAccessTo: dir)
        }
        page.webView = web
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "bridge")
    }

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        let onMessage: (String, [String: Any]) -> Void
        init(onMessage: @escaping (String, [String: Any]) -> Void) { self.onMessage = onMessage }

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let text = message.body as? String, let data = text.data(using: .utf8),
                  let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  let type = obj["type"] as? String else { return }
            onMessage(type, obj["data"] as? [String: Any] ?? [:])
        }

        // The page never navigates anywhere (links in passages are inert).
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(action.request.url?.isFileURL == true ? .allow : .cancel)
        }
    }
}

struct ExamView: View {
    let attemptId: Int
    let onFinished: () -> Void
    let onExit: () -> Void

    @StateObject private var vm: ExamViewModel
    @StateObject private var page = ExamPage()
    @State private var view = "passage"
    @State private var confirmExit = false
    @State private var confirmSubmit = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var sizeClass

    init(attemptId: Int, onFinished: @escaping () -> Void, onExit: @escaping () -> Void) {
        self.attemptId = attemptId
        self.onFinished = onFinished
        self.onExit = onExit
        _vm = StateObject(wrappedValue: ExamViewModel(attemptId: attemptId))
    }

    private var split: Bool { sizeClass == .regular }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            switch vm.phase {
            case .loading, .done: ProgressView().tint(Mn.examBlue)
            case .error:
                VStack(spacing: 14) {
                    Text(vm.error ?? tr("error")).multilineTextAlignment(.center).foregroundStyle(Mn.examText)
                    examButton(tr("retry"), dark: true) { vm.load() }
                    examButton(tr("exit")) { onExit() }
                }
                .padding(32)
            case .intro: intro
            case .running, .submitting: room
            }
            if vm.phase == .submitting {
                Color.white.opacity(0.6).ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView().tint(Mn.examBlue)
                    Text(vm.autoSubmitted ? tr("time_up_submitting") : tr("submitting")).font(.system(size: 15, weight: .semibold)).foregroundStyle(Mn.examText)
                }
            }
        }
        .preferredColorScheme(.light)
        .onAppear { vm.load() }
        .onDisappear { vm.stop() }
        .onChange(of: vm.phase) { _, phase in
            #if DEBUG
            if phase == .intro, UserDefaults.standard.bool(forKey: "e2eAutoStart") { vm.startModule() }
            #endif
            if phase == .done { onFinished() }
            if phase != .running { page.js("ExamRoom.flush(), ExamRoom.setLocked(true)") }
        }
        .onChange(of: scenePhase) { _, s in if s == .active { vm.onForeground() } }
        .alert(tr("leave_q"), isPresented: $confirmExit) {
            Button(tr("exit"), role: .destructive) { onExit() }
            Button(tr("stay"), role: .cancel) {}
        } message: {
            Text(tr("leave_text"))
        }
        .alert(tr("finish_module_q", vm.module?.title ?? tr("module")), isPresented: $confirmSubmit) {
            Button(tr("finish")) { vm.submitModule() }
            Button(tr("cancel"), role: .cancel) {}
        } message: {
            let total = vm.navQuestions.count
            let done = vm.navQuestions.filter { vm.answered($0.question.id) }.count
            Text(tr("answered_of", total, done))
        }
        .alert(tr("error"), isPresented: Binding(get: { vm.error != nil && (vm.phase == .running || vm.phase == .intro) }, set: { if !$0 { vm.error = nil } })) {
            Button("OK") { vm.error = nil }
        } message: { Text(vm.error ?? "") }
    }

    // MARK: intro

    private var intro: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button { confirmExit = true } label: { Image(systemName: "arrow.left").foregroundStyle(Mn.examText) }
                ieltsBadge
                Text(vm.attempt?.test.name ?? "").font(.system(size: 15, weight: .bold)).foregroundStyle(Mn.examText).lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 14).frame(height: 56)
            Rectangle().fill(Mn.examLine).frame(height: 1)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(tr("module_n_of", vm.moduleIndex + 1, vm.attempt?.modules.count ?? 1)).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: 0x4B5563))
                    Text(vm.module?.title ?? "").font(.system(size: 32, weight: .heavy)).foregroundStyle(Mn.examText)
                    HStack(spacing: 16) {
                        Label(Fmt.minutes(vm.module?.durationSeconds ?? 0), systemImage: "timer")
                        Text(tr("parts_questions_short", vm.module?.parts.count ?? 0, vm.module?.parts.reduce(0) { $0 + ($1.questionCount ?? 0) } ?? 0))
                    }
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color(hex: 0x374151))
                    VStack(alignment: .leading, spacing: 10) {
                        Text("INSTRUCTIONS TO CANDIDATES").font(.system(size: 13, weight: .bold)).foregroundStyle(Mn.examText)
                        ForEach(instructions, id: \.self) { Text("•  \($0)").font(.system(size: 15)).foregroundStyle(Color(hex: 0x1F2937)) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16).background(Mn.examPanel).overlay(Rectangle().stroke(Color(hex: 0xE5E7EB)))
                    Text(tr("timer_starts")).font(.system(size: 13)).foregroundStyle(Color(hex: 0x4B5563))
                }
                .padding(24).frame(maxWidth: 640, alignment: .leading)
            }
            Button { vm.startModule() } label: {
                Text(tr("start")).font(.system(size: 16, weight: .bold)).foregroundStyle(.white).frame(maxWidth: .infinity, minHeight: 52).background(Mn.examText)
            }
            .padding(20)
        }
    }

    private var instructions: [String] {
        switch vm.module?.type {
        case "listening": return [tr("ins_l1"), tr("ins_l2"), tr("ins_l3")]
        case "writing": return [tr("ins_w1"), tr("ins_w2"), tr("ins_w3")]
        default: return [tr("ins_r1"), tr("ins_r2"), tr("ins_r3_ios")]
        }
    }

    // MARK: room

    private var room: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button { confirmExit = true } label: { Image(systemName: "arrow.left").foregroundStyle(Mn.examText).frame(width: 32, height: 32) }
                ieltsBadge
                Text(vm.module?.title ?? "").font(.system(size: 15, weight: .bold)).foregroundStyle(Mn.examText)
                Spacer()
                if vm.offline { Image(systemName: "icloud.slash").foregroundStyle(Color(hex: 0xD97706)) }
                timer
                Button { confirmSubmit = true } label: {
                    Text("FINISH").font(.system(size: 12, weight: .bold)).foregroundStyle(Mn.examText)
                        .padding(.horizontal, 10).padding(.vertical, 8).background(Mn.examPanel).overlay(Rectangle().stroke(Mn.examLine))
                }
                .disabled(vm.phase != .running)
            }
            .padding(.horizontal, 12).frame(height: 56)
            Rectangle().fill(Mn.examLine).frame(height: 1)

            if vm.module?.type == "listening" { audioBar }

            if vm.parts.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(vm.parts.enumerated()), id: \.offset) { i, p in
                            let qs = p.payload.sections.flatMap(\.questions)
                            let done = qs.filter { vm.answered($0.id) }.count
                            Button { vm.selectPart(i) } label: {
                                Text("\(p.payload.name ?? "Part \(i + 1)")  \(done)/\(qs.count)")
                                    .font(.system(size: 13, weight: i == vm.partIndex ? .bold : .medium)).foregroundStyle(Mn.examText)
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(i == vm.partIndex ? Color.white : .clear)
                                    .overlay(Rectangle().stroke(i == vm.partIndex ? Mn.examText : .clear))
                            }
                        }
                    }
                    .padding(.horizontal, 8).padding(.vertical, 6)
                }
                .background(Mn.examPanel)
            } else if let p = vm.part {
                Text(p.payload.name ?? "Part 1").font(.system(size: 14, weight: .bold)).foregroundStyle(Mn.examText)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 16).padding(.vertical, 10).background(Mn.examPanel)
            }

            if !split, page.hasPassage[vm.part?.payload.id ?? -1] ?? true {
                let writing = vm.module?.type == "writing"
                HStack(spacing: 0) {
                    tab("passage", writing ? "Task" : "Passage")
                    tab("questions", writing ? "Answer" : "Questions")
                }
                .frame(height: 46)
                Rectangle().fill(Mn.examLine).frame(height: 1)
            }

            ExamWebView(page: page) { type, data in handle(type, data) }
                .onChange(of: page.loaded) { _, _ in render() }
                .onChange(of: vm.partIndex) { _, _ in render() }
                .onChange(of: view) { _, v in page.js("ExamRoom.setView('\(v)')") }
                .onChange(of: vm.flagged) { _, f in page.js("ExamRoom.setFlagged(\(Array(f)))") }

            Rectangle().fill(Mn.examLine).frame(height: 1)
            numberBar
        }
    }

    private func render() {
        guard page.loaded, let p = vm.part else { return }
        let start = p.payload.type == "listening" ? "questions" : "passage"
        view = start
        guard let config = vm.renderConfig(view: start, layout: split ? "split" : "phone") else { return }
        page.js("ExamRoom.render(\(config))")
    }

    private func handle(_ type: String, _ data: [String: Any]) {
        switch type {
        case "loaded": page.loaded = true; render()
        case "ready":
            if let id = data["part_id"] as? Int { page.hasPassage[id] = data["hasPassage"] as? Bool ?? true }
        case "answer":
            guard let partId = data["part_id"] as? Int, let qid = data["question_id"] as? Int else { return }
            let hasText = data.keys.contains("text")
            let hasOptions = data.keys.contains("option_ids")
            vm.onAnswer(partId: partId, questionId: qid, text: data["text"] as? String, optionIds: (data["option_ids"] as? [Any])?.compactMap { ($0 as? NSNumber)?.intValue }, hasText: hasText, hasOptions: hasOptions)
        case "flag":
            if let id = data["question_id"] as? Int { vm.toggleFlag(id) }
        case "marks":
            if let id = data["part_id"] as? Int, let json = try? JSONSerialization.data(withJSONObject: data) { vm.saveMarks(partId: id, json: json) }
        case "view":
            if let v = data["view"] as? String { view = v }
        default: break
        }
    }

    private func tab(_ id: String, _ title: String) -> some View {
        Button { view = id } label: {
            VStack(spacing: 0) {
                Spacer()
                Text(title).font(.system(size: 15, weight: view == id ? .bold : .semibold)).foregroundStyle(view == id ? Mn.examText : Color(hex: 0x4B5563))
                Spacer()
                Rectangle().fill(view == id ? Mn.examBlue : .clear).frame(height: 3)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var ieltsBadge: some View {
        Text("IELTS").font(.system(size: 13, weight: .heavy)).foregroundStyle(.white).padding(.horizontal, 9).padding(.vertical, 5).background(Mn.examRed)
    }

    private var timer: some View {
        let total = Int(vm.remaining)
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        let text = h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
        let warn = total < 300
        return HStack(spacing: 5) {
            Image(systemName: "timer").font(.system(size: 13, weight: .semibold))
            Text(text).font(.system(size: 14, weight: .bold, design: .monospaced))
        }
        .foregroundStyle(warn ? Mn.examTimer : Mn.examText)
        .padding(.horizontal, 9).padding(.vertical, 6)
        .background(Color(hex: 0xF9FAFB)).overlay(Rectangle().stroke(Mn.examLine))
    }

    private var audioBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "headphones").foregroundStyle(Mn.examText)
                Text(vm.audioPlaying ? tr("audio_playing") : "Audio").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color(hex: 0x374151))
                Spacer()
                Image(systemName: "speaker.wave.2").foregroundStyle(Color(hex: 0x374151))
                Slider(value: $vm.volume, in: 0...1).frame(width: 140).tint(Mn.examText)
            }
            .padding(.horizontal, 14).padding(.vertical, 4).background(Color(hex: 0xF9FAFB))
            Rectangle().fill(Mn.examLine).frame(height: 1)
        }
    }

    private var numberBar: some View {
        HStack(spacing: 6) {
            arrow("chevron.left", enabled: vm.partIndex > 0) { vm.selectPart(vm.partIndex - 1) }
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(vm.navQuestions) { q in
                            let answered = vm.answered(q.id)
                            let flagged = vm.flagged.contains(q.id)
                            let inPart = q.partIndex == vm.partIndex
                            Button { pick(q) } label: {
                                Text(q.label).font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(answered ? .white : Color(hex: 0x374151))
                                    .padding(.horizontal, 6).frame(minWidth: 38, minHeight: 44)
                                    .background(answered ? Mn.examText : .white)
                                    .overlay(Rectangle().stroke(flagged ? Color(hex: 0xF97316) : (answered ? Mn.examText : (inPart ? Mn.examBlue : Mn.examLine)), lineWidth: flagged || inPart ? 2 : 1))
                            }
                            .id(q.id)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onChange(of: vm.partIndex) { _, i in
                    if let first = vm.navQuestions.first(where: { $0.partIndex == i }) { withAnimation { proxy.scrollTo(first.id, anchor: .leading) } }
                }
            }
            arrow("chevron.right", enabled: vm.partIndex < vm.parts.count - 1, dark: true) { vm.selectPart(vm.partIndex + 1) }
        }
        .padding(.horizontal, 8).padding(.vertical, 8)
    }

    private func pick(_ q: NavQuestion) {
        if q.partIndex != vm.partIndex {
            vm.selectPart(q.partIndex)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { page.js("ExamRoom.scrollToQuestion(\(q.id))") }
        } else {
            view = "questions"
            page.js("ExamRoom.scrollToQuestion(\(q.id))")
        }
    }

    private func arrow(_ icon: String, enabled: Bool, dark: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                .foregroundStyle(!enabled ? Color(hex: 0x9CA3AF) : (dark ? .white : Mn.examText))
                .frame(width: 44, height: 44)
                .background(dark && enabled ? Mn.examText : Mn.examPanel)
                .overlay(Rectangle().stroke(dark && enabled ? Mn.examText : Mn.examLine))
        }
        .disabled(!enabled)
    }

    private func examButton(_ title: String, dark: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.system(size: 14, weight: .bold)).foregroundStyle(dark ? .white : Mn.examText)
                .padding(.horizontal, 18).padding(.vertical, 12)
                .background(dark ? Mn.examText : Mn.examPanel).overlay(Rectangle().stroke(dark ? Mn.examText : Mn.examLine))
        }
    }
}
