import SwiftUI

/// A skill tab (module = listening | reading | writing) or the full-test list (full, opened from home).
struct TestsView: View {
    let title: String
    let module: String?
    let full: Bool
    var onBack: (() -> Void)?
    @EnvironmentObject private var router: Router
    @State private var search = ""
    @State private var items: [TestItem]?
    @State private var page = 1
    @State private var lastPage = 1
    @State private var error: String?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    if let onBack {
                        Button(action: onBack) {
                            Image(systemName: "arrow.left").font(.system(size: 17, weight: .semibold)).foregroundStyle(Mn.ink2)
                                .frame(width: 44, height: 44).glass(radius: 22)
                        }
                    }
                    ScreenTitle(text: title)
                }
                .padding(.top, 12)
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(Mn.subtle)
                    TextField(tr("search_hint"), text: $search)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .submitLabel(.search)
                }
                .padding(.horizontal, 18).frame(height: 50)
                .glass(radius: 25, strong: true)

                if let error { ErrorCard(message: error) { Task { await load(1) } } }
                if items == nil && error == nil { ProgressView().frame(maxWidth: .infinity).padding(40) }
                if let items, items.isEmpty { Text(tr("nothing_found")).foregroundStyle(Mn.subtle).frame(maxWidth: .infinity).padding(24) }

                ForEach(items ?? []) { t in
                    Button { router.open(.test(t.id, skill: module)) } label: { TestCard(test: t) }.buttonStyle(.plain)
                }
                if items != nil && page < lastPage {
                    Button(tr("load_more")) { Task { await load(page + 1) } }
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(Mn.accent).frame(maxWidth: .infinity).padding(14)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, tabBarSpace)
        }
        .scrollDismissesKeyboard(.interactively)
        .refreshable { await load(1) }
        .task(id: search) {
            try? await Task.sleep(nanoseconds: search.isEmpty ? 0 : 350_000_000)
            if Task.isCancelled { return }
            items = nil
            await load(1)
        }
    }

    private func load(_ p: Int) async {
        error = nil
        do {
            let q = search.trimmingCharacters(in: .whitespaces)
            let query: [String: String?] = ["search": q.isEmpty ? nil : q, "module": module, "full": full ? "1" : nil, "page": String(p)]
            // A full test has content in all three skills (the server also checks; empty modules are not listed).
            let show = { (r: TestsResponse) in
                let data = full ? r.data.filter { $0.modules.count >= 3 } : r.data
                items = p == 1 ? data : (items ?? []) + data
                page = p
                lastPage = r.meta?.lastPage ?? 1
            }
            // The first page without a search comes from the cache at once, then from the network.
            if p == 1 && q.isEmpty { try await API.shared.cached("tests", query: query, show: show) }
            else { show(try await API.shared.send(.get, "tests", query: query)) }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct TestCard: View {
    let test: TestItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(test.name).font(.system(size: 16, weight: .bold)).foregroundStyle(Mn.ink)
                Spacer()
                if test.inProgressAttemptId != nil { Pill(text: tr("in_progress"), bg: Mn.accentSoft, fg: Mn.accentDark) }
                else if test.lastFinishedAttemptId != nil { Pill(text: tr("solved"), bg: Mn.greenSoft, fg: Mn.green) }
            }
            HStack(spacing: 6) {
                ForEach(test.modules, id: \.typeId) { Pill(text: $0.title) }
                Text(Fmt.minutes(test.modules.reduce(0) { $0 + ($1.durationSeconds ?? 0) })).font(.system(size: 13)).foregroundStyle(Mn.subtle)
            }
            if let folder = test.folder { Text(folder.name).font(.system(size: 13)).foregroundStyle(Mn.subtle) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glass()
    }
}

struct TestDetailView: View {
    let testId: Int
    /// Opened from a skill tab: only that skill is ticked; the student may tick the others too.
    var skill: String?
    @EnvironmentObject private var router: Router
    @Environment(\.dismiss) private var dismiss
    @State private var test: TestItem?
    @State private var selected: Set<String> = []
    @State private var error: String?
    @State private var starting = false

    var body: some View {
        ZStack {
            GlassBackground(variant: 1)
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Button { dismiss() } label: {
                        Image(systemName: "arrow.left").font(.system(size: 17, weight: .semibold)).foregroundStyle(Mn.ink2)
                            .frame(width: 44, height: 44).glass(radius: 22)
                    }
                    Text(tr("tests")).font(.system(size: 14, weight: .semibold)).foregroundStyle(Mn.subtle)
                    Spacer()
                }
                .padding(.horizontal, 20).padding(.top, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if let error { ErrorCard(message: error) { Task { await load() } } }
                        if let t = test {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(t.name).font(.system(size: 28, weight: .heavy)).foregroundStyle(Mn.ink)
                                Text([t.folder?.name.trimmingCharacters(in: .whitespaces) ?? "", t.variant == "general" ? "General Training" : "Academic", tr("module_count", t.modules.count), Fmt.minutes(t.modules.reduce(0) { $0 + ($1.durationSeconds ?? 0) })].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(.system(size: 15)).foregroundStyle(Mn.muted)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tr("which_modules")).font(.system(size: 13, weight: .bold)).foregroundStyle(Mn.subtle).padding(.leading, 12).padding(.top, 10)
                                ForEach(t.modules, id: \.typeId) { m in
                                    let on = selected.contains(m.type)
                                    Button {
                                        if on { selected.remove(m.type) } else { selected.insert(m.type) }
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: on ? "checkmark.square.fill" : "square").font(.system(size: 24)).foregroundStyle(on ? Mn.accent : Mn.fieldBorder)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(m.title).font(.system(size: 16, weight: .bold)).foregroundStyle(Mn.ink)
                                                Text(tr("parts_questions", m.partsCount ?? 0, m.questionsCount ?? 0, Fmt.minutes(m.durationSeconds ?? 0))).font(.system(size: 13)).foregroundStyle(Mn.subtle)
                                            }
                                            Spacer()
                                        }
                                        .padding(.horizontal, 12).padding(.vertical, 14)
                                        .background(on ? Mn.raised : .clear, in: RoundedRectangle(cornerRadius: 22))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(8).glass(radius: 28)

                            VStack(alignment: .leading, spacing: 12) {
                                Text(tr("rules")).font(.system(size: 15, weight: .bold)).foregroundStyle(Mn.ink)
                                rule("headphones", tr("rule_audio"))
                                rule("square.and.arrow.down", tr("rule_save"))
                                rule("timer", tr("rule_timer"))
                            }
                            .padding(18).glass()
                        } else if error == nil {
                            ProgressView().frame(maxWidth: .infinity).padding(40)
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 18)
                }

                if let t = test {
                    let chosen = t.modules.filter { selected.contains($0.type) }
                    let all = chosen.count == t.modules.count
                    VStack(spacing: 8) {
                        // Any combination: fewer than all modules go as "listening,reading"; all of them is the full test.
                        PrimaryButton(title: t.inProgressAttemptId != nil ? tr("continue_") : tr("start_with", Fmt.minutes(chosen.reduce(0) { $0 + ($1.durationSeconds ?? 0) })), loading: starting, enabled: !chosen.isEmpty) {
                            start(t, module: all ? nil : chosen.map(\.type).joined(separator: ","))
                        }
                        if let last = t.lastFinishedAttemptId {
                            Button(tr("see_last_result")) { router.open(.result(last)) }.font(.system(size: 14, weight: .semibold)).foregroundStyle(Mn.accent)
                        }
                        if all && chosen.count > 1 { Text(tr("order")).font(.system(size: 13)).foregroundStyle(Mn.subtle) }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 8)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await load() }
    }

    private func rule(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundStyle(Mn.accent).frame(width: 20)
            Text(text).font(.system(size: 14)).foregroundStyle(Mn.muted)
        }
    }

    private func load() async {
        error = nil
        do {
            // Cached copy first, then the fresh one (its running / finished attempt ids decide the button).
            try await API.shared.cached("tests/\(testId)") { (r: TestResponse) in
                let first = test == nil
                test = r.test
                if first {
                    selected = skill.flatMap { s in r.test.modules.contains { $0.type == s } ? [s] : nil } ?? Set(r.test.modules.map(\.type))
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func start(_ t: TestItem, module: String?) {
        starting = true
        Task {
            defer { starting = false }
            do {
                struct Body: Encodable { let testId: Int; let module: String? }
                let r: AttemptEnvelope = try await API.shared.send(.post, "attempts", body: Body(testId: t.id, module: module))
                router.openExam(r.attempt.id)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}
