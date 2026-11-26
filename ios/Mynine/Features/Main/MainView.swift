import SwiftUI

enum Tab: Int, CaseIterable {
    case home, listening, reading, writing, attempts

    /// Skill tabs keep their English exam names in every language.
    var title: String {
        switch self {
        case .home: return tr("nav_home")
        case .listening: return "Listening"
        case .reading: return "Reading"
        case .writing: return "Writing"
        case .attempts: return tr("attempts")
        }
    }
    var icon: String { ["house", "headphones", "book", "pencil", "clock"][rawValue] }
    var selectedIcon: String { ["house.fill", "headphones", "book.fill", "pencil", "clock.fill"][rawValue] }
    var module: String? { [nil, "listening", "reading", "writing", nil][rawValue] }
}

/// Screens of the home tab without a tab of their own: Home stays lit and back returns home.
enum HomeChild: String { case profile, fullTests }

struct MainView: View {
    #if DEBUG
    /// Simulator checks: `-e2eTab 1` opens Listening, `-e2eChild profile|fullTests` a home screen.
    @State private var tab: Tab = Tab(rawValue: UserDefaults.standard.integer(forKey: "e2eTab")) ?? .home
    @State private var child: HomeChild? = HomeChild(rawValue: UserDefaults.standard.string(forKey: "e2eChild") ?? "")
    #else
    @State private var tab: Tab = .home
    @State private var child: HomeChild?
    #endif

    var body: some View {
        ZStack(alignment: .bottom) {
            GlassBackground(variant: tab.rawValue)
            Group {
                switch (child, tab) {
                case (.profile?, _): ProfileView(openHistory: { child = nil; tab = .attempts }, onBack: { child = nil })
                case (.fullTests?, _): TestsView(title: tr("full_tests"), module: nil, full: true, onBack: { child = nil })
                case (nil, .home): HomeView(
                    openSkill: { m in tab = Tab.allCases.first { $0.module == m } ?? .home },
                    openFullTests: { child = .fullTests },
                    openProfile: { child = .profile }
                )
                case (nil, .attempts): HistoryView()
                case (nil, let t): TestsView(title: t.title, module: t.module, full: false).id(t)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            TabBar(current: child != nil ? .home : tab) { child = nil; tab = $0 }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// Space the floating tab bar covers.
let tabBarSpace: CGFloat = 96

/// Floating tab bar (same design as the MultiTest app): a card with a pill that slides to the chosen tab.
struct TabBar: View {
    let current: Tab
    let select: (Tab) -> Void
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { t in
                let on = t == current
                Button { if !on { select(t) } } label: {
                    VStack(spacing: 2) {
                        Image(systemName: on ? t.selectedIcon : t.icon).font(.system(size: 21, weight: .semibold)).frame(height: 26)
                        Text(t.title).font(.system(size: 10, weight: .bold)).lineLimit(1).minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(on ? Mn.accent : Mn.subtle)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        if on { RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Mn.accentSoft).matchedGeometryEffect(id: "pill", in: pill) }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .frame(height: 62)
        .background(Mn.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Mn.line))
        .shadow(color: .black.opacity(0.12), radius: 14, y: 6)
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: current)
    }
}

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
                Pill(text: tr("in_progress"), bg: Mn.accentSoft, fg: Mn.accentDark)
            }
        }
        .padding(16)
        .glass(radius: 22)
    }

    private var modules: String {
        if let m = item.module { return Fmt.module(m) }
        if let list = item.modules, !list.isEmpty { return list.map(Fmt.module).joined(separator: " · ") }
        return tr("full_test")
    }
}

struct HomeView: View {
    let openSkill: (String) -> Void
    let openFullTests: () -> Void
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
                        Text(session.user?.name.split(separator: " ").first.map(String.init) ?? tr("student")).font(.system(size: 26, weight: .heavy)).foregroundStyle(Mn.ink)
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
                        Text(tr("first_test_title")).font(.system(size: 18, weight: .bold)).foregroundStyle(Mn.ink)
                        Text(tr("first_test_text")).font(.system(size: 14)).foregroundStyle(Mn.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(20).glass(radius: 28)
                }

                if let running = attempts?.first(where: { $0.status != "completed" }) {
                    Button { router.openExam(running.id) } label: { continueCard(running) }.buttonStyle(.plain)
                }

                Text(tr("modules")).font(.system(size: 17, weight: .bold)).foregroundStyle(Mn.ink)
                HStack(spacing: 10) {
                    moduleTile("Listening", icon: "headphones", tint: Mn.listeningTint, bg: Color(hex: 0x38BDF8, alpha: 0.18)) { openSkill("listening") }
                    moduleTile("Reading", icon: "book", tint: Mn.accentDark, bg: Mn.accentSoft) { openSkill("reading") }
                    moduleTile("Writing", icon: "pencil", tint: Mn.writingTint, bg: Color(hex: 0xEC4899, alpha: 0.16)) { openSkill("writing") }
                }

                HStack {
                    Text(tr("full_tests")).font(.system(size: 17, weight: .bold)).foregroundStyle(Mn.ink)
                    Spacer()
                    Button(tr("all")) { openFullTests() }.font(.system(size: 14, weight: .semibold)).foregroundStyle(Mn.accent)
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
        case 5...10: return tr("good_morning")
        case 11...17: return tr("good_day")
        default: return tr("good_evening")
        }
    }

    private func load() async {
        error = nil
        // In parallel, each from the cache first (the network is the slow part on phones).
        async let a: Void = API.shared.cached("attempts", query: ["page": "1"]) { (r: AttemptsResponse) in attempts = r.data }
        async let t: Void = API.shared.cached("tests", query: ["full": "1"]) { (r: TestsResponse) in
            tests = Array(r.data.filter { $0.modules.count >= 3 }.prefix(4))
        }
        async let me: UserResponse? = try? API.shared.send(.get, "me")
        do {
            _ = try await (a, t)
        } catch {
            self.error = error.localizedDescription
        }
        if let me = await me { session.update(me.user) }
    }

    private func bandCard(_ item: AttemptSummary) -> some View {
        let b = item.bands
        return HStack(spacing: 18) {
            BandRing(value: b?.overall ?? b?.listening ?? b?.reading ?? b?.writing)
            VStack(alignment: .leading, spacing: 8) {
                Text(b?.overall != nil ? tr("last_overall") : tr("last_result")).font(.system(size: 13, weight: .semibold)).foregroundStyle(Mn.subtle)
                HStack(spacing: 6) {
                    if let v = b?.listening { Pill(text: "L \(Fmt.band(v))") }
                    if let v = b?.reading { Pill(text: "R \(Fmt.band(v))") }
                    if let v = b?.writing { Pill(text: "W \(Fmt.band(v))") }
                }
                Text(tr("see_result")).font(.system(size: 14, weight: .semibold)).foregroundStyle(Mn.accent)
            }
            Spacer()
        }
        .padding(18).glass(radius: 28)
    }

    private func continueCard(_ item: AttemptSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(tr("continue_caps")).font(.system(size: 12, weight: .bold)).foregroundStyle(Color(hex: 0xE0E7FF)).tracking(1)
            Text((item.test.name ?? "Test") + (item.module.map { " · " + Fmt.module($0) } ?? "")).font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
            Text(tr("unfinished")).font(.system(size: 14)).foregroundStyle(Color(hex: 0xE0E7FF))
            Text(tr("continue_")).font(.system(size: 14, weight: .bold)).foregroundStyle(Color(hex: 0x4338CA))
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
                ScreenTitle(text: tr("attempts")).padding(.top, 12).padding(.bottom, 8)
                if let error { ErrorCard(message: error) { Task { await load(1) } } }
                if items == nil && error == nil { ProgressView().frame(maxWidth: .infinity).padding(40) }
                if let items, items.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tr("no_attempts")).font(.system(size: 16, weight: .bold)).foregroundStyle(Mn.ink)
                        Text(tr("no_attempts_text")).font(.system(size: 14)).foregroundStyle(Mn.muted)
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
                    Button(tr("load_more")) { Task { await load(page + 1) } }
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
            let show = { (r: AttemptsResponse) in
                items = p == 1 ? r.data : (items ?? []) + r.data
                page = p
                lastPage = r.meta?.lastPage ?? 1
            }
            if p == 1 { try await API.shared.cached("attempts", query: ["page": "1"], show: show) }
            else { show(try await API.shared.send(.get, "attempts", query: ["page": String(p)])) }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct ProfileView: View {
    let openHistory: () -> Void
    let onBack: () -> Void
    @EnvironmentObject private var session: Session
    @EnvironmentObject private var prefs: Prefs
    @State private var pickLanguage = false
    @State private var pickTheme = false
    @State private var editing = false
    @State private var newName = ""
    @State private var confirmDelete = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Button(action: onBack) {
                        Image(systemName: "arrow.left").font(.system(size: 17, weight: .semibold)).foregroundStyle(Mn.ink2)
                            .frame(width: 44, height: 44).glass(radius: 22)
                    }
                    ScreenTitle(text: tr("profile"))
                }
                .padding(.top, 12)

                Button { newName = session.user?.name ?? ""; editing = true } label: {
                    HStack(spacing: 14) {
                        Avatar(name: session.user?.name ?? "", size: 64)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.user?.name ?? "").font(.system(size: 19, weight: .bold)).foregroundStyle(Mn.ink)
                            if let e = session.user?.email ?? session.user?.username { Text(mask(e)).font(.system(size: 14)).foregroundStyle(Mn.subtle) }
                            Pill(text: tr("mynine_student"), bg: Mn.accentSoft, fg: Mn.accentDark)
                        }
                        Spacer()
                    }
                    .padding(18).glass(radius: 28)
                }
                .buttonStyle(.plain)

                VStack(spacing: 0) {
                    row("person.text.rectangle", tr("change_name")) { newName = session.user?.name ?? ""; editing = true }
                    Divider()
                    row("paperplane", "Telegram", value: session.user?.telegramConnected == true ? tr("connected") : tr("not_connected"), valueColor: session.user?.telegramConnected == true ? Mn.green : Mn.subtle)
                    Divider()
                    row("clock", tr("history"), value: "›", action: openHistory)
                    Divider()
                    row("globe", tr("language"), value: prefs.languageName(prefs.language)) { pickLanguage = true }
                    Divider()
                    row("moon", tr("theme"), value: prefs.themeName(prefs.theme)) { pickTheme = true }
                }
                .glass()

                VStack(spacing: 0) {
                    row("rectangle.portrait.and.arrow.right", tr("exit")) {
                        Task {
                            _ = try? await API.shared.data(.post, "auth/logout")
                            session.clear()
                        }
                    }
                    Divider()
                    row("trash", tr("delete_account"), tint: Mn.red) { confirmDelete = true }
                }
                .glass()

                if let error { Text(error).font(.system(size: 14)).foregroundStyle(Mn.red) }

                HStack(spacing: 0) {
                    Text("Mynine \(API.shared.appVersion) · ").font(.system(size: 13)).foregroundStyle(Mn.subtle)
                    Link(tr("privacy"), destination: API.shared.baseURL.appendingPathComponent("privacy")).font(.system(size: 13, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, tabBarSpace)
        }
        .confirmationDialog(tr("language"), isPresented: $pickLanguage, titleVisibility: .visible) {
            ForEach(Prefs.Language.allCases, id: \.self) { l in
                Button((l == prefs.language ? "✓ " : "") + prefs.languageName(l)) { prefs.language = l }
            }
            Button(tr("cancel"), role: .cancel) {}
        }
        .confirmationDialog(tr("theme"), isPresented: $pickTheme, titleVisibility: .visible) {
            ForEach(Prefs.Theme.allCases, id: \.self) { t in
                Button((t == prefs.theme ? "✓ " : "") + prefs.themeName(t)) { prefs.theme = t }
            }
            Button(tr("cancel"), role: .cancel) {}
        }
        .alert(tr("name"), isPresented: $editing) {
            TextField(tr("full_name"), text: $newName)
            Button(tr("save")) {
                Task {
                    do {
                        let r: UserResponse = try await API.shared.send(.patch, "me", body: ["name": newName.trimmingCharacters(in: .whitespaces)])
                        session.update(r.user)
                    } catch { self.error = error.localizedDescription }
                }
            }
            Button(tr("cancel"), role: .cancel) {}
        }
        .alert(tr("delete_q"), isPresented: $confirmDelete) {
            Button(tr("delete"), role: .destructive) {
                Task {
                    do {
                        _ = try await API.shared.data(.delete, "me")
                        session.clear()
                    } catch { self.error = error.localizedDescription }
                }
            }
            Button(tr("cancel"), role: .cancel) {}
        } message: {
            Text(tr("delete_text"))
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
