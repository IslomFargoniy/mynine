import SwiftUI

private let filters: [(String?, String)] = [(nil, "Hammasi"), ("listening", "Listening"), ("reading", "Reading"), ("writing", "Writing")]

struct TestsView: View {
    let initialModule: String?
    @EnvironmentObject private var router: Router
    @State private var module: String?
    @State private var search = ""
    @State private var items: [TestItem]?
    @State private var page = 1
    @State private var lastPage = 1
    @State private var error: String?
    @State private var started = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ScreenTitle(text: "Testlar").padding(.top, 12)
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(Mn.subtle)
                    TextField("Test nomi bo'yicha qidirish", text: $search)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .submitLabel(.search)
                }
                .padding(.horizontal, 18).frame(height: 50)
                .glass(radius: 25, strong: true)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filters, id: \.1) { f in
                            let on = module == f.0
                            Button { module = f.0 } label: {
                                Text(f.1).font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(on ? .white : Mn.ink2)
                                    .padding(.horizontal, 16).padding(.vertical, 9)
                                    .background(on ? Mn.accent : Color.white.opacity(0.55), in: Capsule())
                                    .overlay(Capsule().stroke(on ? .clear : Mn.glassEdge))
                            }
                        }
                    }
                }

                if let error { ErrorCard(message: error) { Task { await load(1) } } }
                if items == nil && error == nil { ProgressView().frame(maxWidth: .infinity).padding(40) }
                if let items, items.isEmpty { Text("Hech narsa topilmadi.").foregroundStyle(Mn.subtle).frame(maxWidth: .infinity).padding(24) }

                ForEach(items ?? []) { t in
                    Button { router.open(.test(t.id)) } label: { TestCard(test: t) }.buttonStyle(.plain)
                }
                if items != nil && page < lastPage {
                    Button("Yana yuklash") { Task { await load(page + 1) } }
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(Mn.accent).frame(maxWidth: .infinity).padding(14)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, tabBarSpace)
        }
        .scrollDismissesKeyboard(.interactively)
        .refreshable { await load(1) }
        .onAppear {
            if !started { started = true; module = initialModule }
        }
        .task(id: "\(module ?? "")|\(search)") {
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
            let r: TestsResponse = try await API.shared.send(.get, "tests", query: ["search": q.isEmpty ? nil : q, "module": module, "page": String(p)])
            items = p == 1 ? r.data : (items ?? []) + r.data
            page = p
            lastPage = r.meta?.lastPage ?? 1
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
                if test.inProgressAttemptId != nil { Pill(text: "Davom etmoqda", bg: Mn.accentSoft, fg: Mn.accentDark) }
                else if test.lastFinishedAttemptId != nil { Pill(text: "Yechilgan", bg: Mn.greenSoft, fg: Mn.green) }
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
                    Text("Testlar").font(.system(size: 14, weight: .semibold)).foregroundStyle(Mn.subtle)
                    Spacer()
                }
                .padding(.horizontal, 20).padding(.top, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if let error { ErrorCard(message: error) { Task { await load() } } }
                        if let t = test {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(t.name).font(.system(size: 28, weight: .heavy)).foregroundStyle(Mn.ink)
                                Text([t.variant == "general" ? "General Training" : "Academic", "\(t.modules.count) modul", Fmt.minutes(t.modules.reduce(0) { $0 + ($1.durationSeconds ?? 0) })].joined(separator: " · "))
                                    .font(.system(size: 15)).foregroundStyle(Mn.muted)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Qaysi modullarni yechasiz?").font(.system(size: 13, weight: .bold)).foregroundStyle(Mn.subtle).padding(.leading, 12).padding(.top, 10)
                                ForEach(t.modules, id: \.typeId) { m in
                                    let on = selected.contains(m.type)
                                    Button {
                                        if on { selected.remove(m.type) } else { selected.insert(m.type) }
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: on ? "checkmark.square.fill" : "square").font(.system(size: 24)).foregroundStyle(on ? Mn.accent : Color(hex: 0x94A3B8))
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(m.title).font(.system(size: 16, weight: .bold)).foregroundStyle(Mn.ink)
                                                Text("\(m.partsCount ?? 0) part · \(m.questionsCount ?? 0) savol · \(Fmt.minutes(m.durationSeconds ?? 0))").font(.system(size: 13)).foregroundStyle(Mn.subtle)
                                            }
                                            Spacer()
                                        }
                                        .padding(.horizontal, 12).padding(.vertical, 14)
                                        .background(on ? Color.white.opacity(0.85) : .clear, in: RoundedRectangle(cornerRadius: 22))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(8).glass(radius: 28)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Qoidalar").font(.system(size: 15, weight: .bold)).foregroundStyle(Mn.ink)
                                rule("headphones", "Listening audiosi faqat bir marta ijro etiladi. Quloqchin taqing.")
                                rule("square.and.arrow.down", "Javoblar avtomatik saqlanadi — internet uzilsa ham davom etasiz.")
                                rule("timer", "Vaqt server bo'yicha hisoblanadi, ilovadan chiqsangiz ham to'xtamaydi.")
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
                    let ready = !chosen.isEmpty && (chosen.count == 1 || chosen.count == t.modules.count)
                    VStack(spacing: 8) {
                        if !ready && !chosen.isEmpty { Text("Bitta modulni yoki to'liq testni tanlang.").font(.system(size: 13)).foregroundStyle(Mn.subtle) }
                        PrimaryButton(title: t.inProgressAttemptId != nil ? "Davom etish" : "Boshlash · \(Fmt.minutes(chosen.reduce(0) { $0 + ($1.durationSeconds ?? 0) }))", loading: starting, enabled: ready) {
                            start(t, module: chosen.count == 1 && t.modules.count > 1 ? chosen[0].type : nil)
                        }
                        if let last = t.lastFinishedAttemptId {
                            Button("Oxirgi natijani ko'rish") { router.open(.result(last)) }.font(.system(size: 14, weight: .semibold)).foregroundStyle(Mn.accent)
                        }
                        Text("Tartib: Listening → Reading → Writing").font(.system(size: 13)).foregroundStyle(Mn.subtle)
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
            let r: TestResponse = try await API.shared.send(.get, "tests/\(testId)")
            test = r.test
            selected = Set(r.test.modules.map(\.type))
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
