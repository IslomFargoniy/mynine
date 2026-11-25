import SwiftUI

@main
struct MynineApp: App {
    @StateObject private var session = Session.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .preferredColorScheme(.light)
                .tint(Mn.accent)
        }
    }
}

enum Route: Hashable {
    case test(Int)
    case result(Int)
}

/// Navigation shared by the tabs: push a test / result, open the exam full screen.
@MainActor
final class Router: ObservableObject {
    @Published var path = NavigationPath()
    @Published var exam: ExamTarget?

    struct ExamTarget: Identifiable { let id: Int }

    func open(_ route: Route) { path.append(route) }
    func openExam(_ attemptId: Int) { exam = ExamTarget(id: attemptId) }

    func examFinished(_ attemptId: Int) {
        exam = nil
        path = NavigationPath()
        path.append(Route.result(attemptId))
    }
}

struct RootView: View {
    @EnvironmentObject private var session: Session
    @StateObject private var router = Router()

    var body: some View {
        Group {
            if session.user != nil {
                NavigationStack(path: $router.path) {
                    MainView()
                        .navigationDestination(for: Route.self) { route in
                            switch route {
                            case .test(let id): TestDetailView(testId: id)
                            case .result(let id): ResultView(attemptId: id)
                            }
                        }
                }
                .fullScreenCover(item: $router.exam) { target in
                    ExamView(attemptId: target.id) { router.examFinished(target.id) } onExit: { router.exam = nil }
                }
                .environmentObject(router)
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: session.user == nil)
        #if DEBUG
        .task { await debugLaunch() }
        #endif
    }

    #if DEBUG
    /// Simulator checks only: `-e2eToken <token>` signs in, `-e2eRoute test:1 | exam:2 | result:1` opens a screen.
    private func debugLaunch() async {
        let defaults = UserDefaults.standard
        if let token = defaults.string(forKey: "e2eToken") {
            API.shared.token = token
            if let me: UserResponse = try? await API.shared.send(.get, "me") { session.signIn(AuthResponse(token: token, user: me.user)) }
        }
        guard let route = defaults.string(forKey: "e2eRoute"), let id = Int(route.split(separator: ":").last ?? "") else { return }
        try? await Task.sleep(nanoseconds: 500_000_000)
        if route.hasPrefix("test:") { router.open(.test(id)) }
        if route.hasPrefix("result:") { router.open(.result(id)) }
        if route.hasPrefix("exam:") { router.openExam(id) }
    }
    #endif
}
