import SwiftUI

enum Tab: Int, CaseIterable {
    case home, tests, history, profile

    var title: String { ["Bosh", "Testlar", "Tarix", "Profil"][rawValue] }
    var icon: String { ["house", "book", "clock", "person"][rawValue] }
}

struct MainView: View {
    @State private var tab: Tab = .home
    @State private var testsModule: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            GlassBackground(variant: tab.rawValue)
            Group {
                switch tab {
                case .home: HomeView(openTests: { testsModule = $0; tab = .tests }, openProfile: { tab = .profile })
                case .tests: TestsView(initialModule: testsModule)
                case .history: HistoryView()
                case .profile: ProfileView(openHistory: { tab = .history })
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 4) {
                ForEach(Tab.allCases, id: \.self) { t in
                    Button {
                        if t != .tests { testsModule = nil }
                        tab = t
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: t.icon).font(.system(size: 18, weight: .semibold))
                            Text(t.title).font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(tab == t ? .white : Mn.muted)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(tab == t ? Mn.accent : .clear, in: Capsule())
                    }
                }
            }
            .padding(6)
            .frame(height: 68)
            .glass(radius: 34, strong: true)
            .shadow(color: Mn.ink.opacity(0.12), radius: 20, y: 10)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// Space the floating tab bar covers.
let tabBarSpace: CGFloat = 110

struct AttemptRow: View {
    let item: AttemptSummary

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.test.name ?? "Test").font(.system(size: 15, weight: .bold)).foregroundStyle(Mn.ink).lineLimit(1)
                Text("\(modules) · \(Fmt.shortDate(item.startedAt))").font(.system(size: 13)).foregroundStyle(Mn.subtle)
            }
            Spacer()
            if item.status == "completed" {
                let b = item.bands
                Pill(text: "Band \(Fmt.band(b?.overall ?? b?.listening ?? b?.reading ?? b?.writing))", bg: Mn.greenSoft, fg: Mn.green)
            } else {
                Pill(text: "Davom etmoqda", bg: Mn.accentSoft, fg: Mn.accentDark)
            }
        }
        .padding(16)
        .glass(radius: 22)
    }

    private var modules: String {
        if let m = item.module { return Fmt.module(m) }
        if let list = item.modules, !list.isEmpty { return list.map(Fmt.module).joined(separator: " · ") }
        return "To'liq test"
    }
}

struct HomeView: View {
    let openTests: (String?) -> Void
    let openProfile: () -> Void
    @EnvironmentObject private var session: Session
    @EnvironmentObject private var router: Router
    @State private var attempts: [AttemptSummary]?
    @State private var tests: [TestItem] = []
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greeting).font(.system(size: 14, weight: .medium)).foregroundStyle(Mn.subtle)
                        Text(session.user?.name.split(separator: " ").first.map(String.init) ?? "Talaba").font(.system(size: 26, weight: .heavy)).foregroundStyle(Mn.ink)
                    }
                    Spacer()
                    Button(action: openProfile) { Avatar(name: session.user?.name ?? "") }
                }
                .padding(.top, 12)

                if let error { ErrorCard(message: error) { Task { await load() } } }

                if let done = attempts?.first(where: { $0.status == "completed" }) {
                    Button { router.open(.result(done.id)) } label: { bandCard(done) }.buttonStyle(.plain)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Birinchi testingizni yeching").font(.system(size: 18, weight: .bold)).foregroundStyle(Mn.ink)
                        Text("Natijangiz shu yerda ko'rinadi: overall band va har bir modul bo'yicha ball.").font(.system(size: 14)).foregroundStyle(Mn.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(20).glass(radius: 28)
                }

                if let running = attempts?.first(where: { $0.status != "completed" }) {
                    Button { router.openExam(running.id) } label: { continueCard(running) }.buttonStyle(.plain)
                }

                Text("Modullar").font(.system(size: 17, weight: .bold)).foregroundStyle(Mn.ink)
                HStack(spacing: 10) {
                    moduleTile("Listening", icon: "headphones", tint: Color(hex: 0x0369A1), bg: Mn.sky.opacity(0.18)) { openTests("listening") }
                    moduleTile("Reading", icon: "book", tint: Mn.accentDark, bg: Mn.accentSoft) { openTests("reading") }
                    moduleTile("Writing", icon: "pencil", tint: Color(hex: 0xBE185D), bg: Mn.pink.opacity(0.16)) { openTests("writing") }
                }

                HStack {
                    Text("Yangi testlar").font(.system(size: 17, weight: .bold)).foregroundStyle(Mn.ink)
                    Spacer()
                    Button("Hammasi") { openTests(nil) }.font(.system(size: 14, weight: .semibold)).foregroundStyle(Mn.accent)
                }
                ForEach(tests) { t in
                    Button { router.open(.test(t.id)) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(t.name).font(.system(size: 15, weight: .bold)).foregroundStyle(Mn.ink)
                                Text([t.folder?.name.trimmingCharacters(in: .whitespaces), t.modules.map { String($0.title.prefix(1)) }.joined(separator: " · "), Fmt.minutes(t.modules.reduce(0) { $0 + ($1.durationSeconds ?? 0) })].compactMap { $0 }.joined(separator: " · "))
                                    .font(.system(size: 13)).foregroundStyle(Mn.subtle)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(Mn.subtle)
                        }
                        .padding(16).glass(radius: 22)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, tabBarSpace)
        }
        .refreshable { await load() }
        .task { await load() }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5...10: return "Xayrli tong,"
        case 11...17: return "Xayrli kun,"
        default: return "Xayrli kech,"
        }
    }

    private func load() async {
        error = nil
        do {
            let a: AttemptsResponse = try await API.shared.send(.get, "attempts")
            attempts = a.data
            let t: TestsResponse = try await API.shared.send(.get, "tests")
            tests = Array(t.data.prefix(4))
            if let me: UserResponse = try? await API.shared.send(.get, "me") { session.update(me.user) }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func bandCard(_ item: AttemptSummary) -> some View {
        let b = item.bands
        return HStack(spacing: 18) {
            BandRing(value: b?.overall ?? b?.listening ?? b?.reading ?? b?.writing)
            VStack(alignment: .leading, spacing: 8) {
                Text(b?.overall != nil ? "Oxirgi overall band" : "Oxirgi natija").font(.system(size: 13, weight: .semibold)).foregroundStyle(Mn.subtle)
                HStack(spacing: 6) {
                    if let v = b?.listening { Pill(text: "L \(Fmt.band(v))") }
                    if let v = b?.reading { Pill(text: "R \(Fmt.band(v))") }
                    if let v = b?.writing { Pill(text: "W \(Fmt.band(v))") }
                }
                Text("Natijani ko'rish →").font(.system(size: 14, weight: .semibold)).foregroundStyle(Mn.accent)
            }
            Spacer()
        }
        .padding(18).glass(radius: 28)
    }

    private func continueCard(_ item: AttemptSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DAVOM ETTIRISH").font(.system(size: 12, weight: .bold)).foregroundStyle(Color(hex: 0xE0E7FF)).tracking(1)
            Text((item.test.name ?? "Test") + (item.module.map { " · " + Fmt.module($0) } ?? "")).font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
            Text("Tugallanmagan test — qolgan joyidan davom eting.").font(.system(size: 14)).foregroundStyle(Color(hex: 0xE0E7FF))
            Text("Davom etish").font(.system(size: 14, weight: .bold)).foregroundStyle(Mn.accentDark)
                .padding(.horizontal, 18).padding(.vertical, 10).background(.white, in: Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Mn.accent, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Mn.accent.opacity(0.35), radius: 14, y: 10)
    }

    private func moduleTile(_ title: String, icon: String, tint: Color, bg: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(tint)
                    .frame(width: 36, height: 36).background(bg, in: RoundedRectangle(cornerRadius: 12))
                Text(title).font(.system(size: 14, weight: .bold)).foregroundStyle(Mn.ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12).padding(.vertical, 14)
            .glass(radius: 22)
        }
        .buttonStyle(.plain)
    }
}

struct HistoryView: View {
    @EnvironmentObject private var router: Router
    @State private var items: [AttemptSummary]?
    @State private var page = 1
    @State private var lastPage = 1
    @State private var error: String?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                ScreenTitle(text: "Tarix").padding(.top, 12).padding(.bottom, 8)
                if let error { ErrorCard(message: error) { Task { await load(1) } } }
                if items == nil && error == nil { ProgressView().frame(maxWidth: .infinity).padding(40) }
                if let items, items.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hali test yechmagansiz").font(.system(size: 16, weight: .bold)).foregroundStyle(Mn.ink)
                        Text("Testlar bo'limidan birinchi testingizni boshlang.").font(.system(size: 14)).foregroundStyle(Mn.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(18).glass()
                }
                ForEach(items ?? []) { a in
                    Button {
                        if a.status == "completed" { router.open(.result(a.id)) } else { router.openExam(a.id) }
                    } label: { AttemptRow(item: a) }
                    .buttonStyle(.plain)
                }
                if items != nil && page < lastPage {
                    Button("Yana yuklash") { Task { await load(page + 1) } }
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(Mn.accent).frame(maxWidth: .infinity).padding(14)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, tabBarSpace)
        }
        .refreshable { await load(1) }
        .task { await load(1) }
    }

    private func load(_ p: Int) async {
        error = nil
        do {
            let r: AttemptsResponse = try await API.shared.send(.get, "attempts", query: ["page": String(p)])
            items = p == 1 ? r.data : (items ?? []) + r.data
            page = p
            lastPage = r.meta?.lastPage ?? 1
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct ProfileView: View {
    let openHistory: () -> Void
    @EnvironmentObject private var session: Session
    @State private var editing = false
    @State private var newName = ""
    @State private var confirmDelete = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenTitle(text: "Profil").padding(.top, 12)

                Button { newName = session.user?.name ?? ""; editing = true } label: {
                    HStack(spacing: 14) {
                        Avatar(name: session.user?.name ?? "", size: 64)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.user?.name ?? "").font(.system(size: 19, weight: .bold)).foregroundStyle(Mn.ink)
                            if let e = session.user?.email ?? session.user?.username { Text(mask(e)).font(.system(size: 14)).foregroundStyle(Mn.subtle) }
                            Pill(text: "Mynine talabasi", bg: Mn.accentSoft, fg: Mn.accentDark)
                        }
                        Spacer()
                    }
                    .padding(18).glass(radius: 28)
                }
                .buttonStyle(.plain)

                VStack(spacing: 0) {
                    row("person.text.rectangle", "Ismni o'zgartirish") { newName = session.user?.name ?? ""; editing = true }
                    Divider()
                    row("paperplane", "Telegram", value: session.user?.telegramConnected == true ? "Ulangan" : "Ulanmagan", valueColor: session.user?.telegramConnected == true ? Mn.green : Mn.subtle)
                    Divider()
                    row("clock", "Urinishlar tarixi", value: "›", action: openHistory)
                }
                .glass()

                VStack(spacing: 0) {
                    row("rectangle.portrait.and.arrow.right", "Chiqish") {
                        Task {
                            _ = try? await API.shared.data(.post, "auth/logout")
                            session.clear()
                        }
                    }
                    Divider()
                    row("trash", "Hisobni o'chirish", tint: Mn.red) { confirmDelete = true }
                }
                .glass()

                if let error { Text(error).font(.system(size: 14)).foregroundStyle(Mn.red) }

                HStack(spacing: 0) {
                    Text("Mynine \(API.shared.appVersion) · ").font(.system(size: 13)).foregroundStyle(Mn.subtle)
                    Link("Maxfiylik siyosati", destination: API.shared.baseURL.appendingPathComponent("privacy")).font(.system(size: 13, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, tabBarSpace)
        }
        .alert("Ism", isPresented: $editing) {
            TextField("Ism va familiya", text: $newName)
            Button("Saqlash") {
                Task {
                    do {
                        let r: UserResponse = try await API.shared.send(.patch, "me", body: ["name": newName.trimmingCharacters(in: .whitespaces)])
                        session.update(r.user)
                    } catch { self.error = error.localizedDescription }
                }
            }
            Button("Bekor qilish", role: .cancel) {}
        }
        .alert("Hisobni o'chirasizmi?", isPresented: $confirmDelete) {
            Button("O'chirish", role: .destructive) {
                Task {
                    do {
                        _ = try await API.shared.data(.delete, "me")
                        session.clear()
                    } catch { self.error = error.localizedDescription }
                }
            }
            Button("Bekor qilish", role: .cancel) {}
        } message: {
            Text("Hisobingiz va unga bog'langan ma'lumotlar butunlay o'chiriladi. Bu amalni qaytarib bo'lmaydi.")
        }
    }

    private func row(_ icon: String, _ title: String, value: String? = nil, valueColor: Color = Mn.subtle, tint: Color = Mn.accent, action: (() -> Void)? = nil) -> some View {
        Button { action?() } label: {
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundStyle(tint).frame(width: 22)
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(tint == Mn.red ? Mn.red : Mn.ink)
                Spacer()
                if let value { Text(value).font(.system(size: 15, weight: .medium)).foregroundStyle(valueColor) }
            }
            .padding(.horizontal, 16).padding(.vertical, 17)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }

    private func mask(_ value: String) -> String {
        guard let at = value.firstIndex(of: "@"), value.distance(from: value.startIndex, to: at) > 1 else { return value }
        let count = min(6, value.distance(from: value.startIndex, to: at) - 1)
        return String(value.first!) + String(repeating: "•", count: count) + String(value[at...])
    }
}
