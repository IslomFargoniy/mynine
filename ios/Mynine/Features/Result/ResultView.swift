import SwiftUI

struct ResultView: View {
    let attemptId: Int
    @Environment(\.dismiss) private var dismiss
    @State private var result: ResultResponse?
    @State private var error: String?
    @State private var selected: String?

    var body: some View {
        ZStack {
            GlassBackground(variant: 2)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Button { dismiss() } label: {
                            Image(systemName: "arrow.left").font(.system(size: 17, weight: .semibold)).foregroundStyle(Mn.ink2).frame(width: 44, height: 44).glass(radius: 22)
                        }
                        VStack(alignment: .leading) {
                            Text(result?.attempt.test.name ?? "Natija").font(.system(size: 17, weight: .bold)).foregroundStyle(Mn.ink)
                            if let a = result?.attempt { Text(Fmt.shortDate(a.finishedAt ?? a.startedAt)).font(.system(size: 13)).foregroundStyle(Mn.subtle) }
                        }
                    }
                    if let error { ErrorCard(message: error) { Task { await load() } } }
                    if result == nil && error == nil { ProgressView().frame(maxWidth: .infinity).padding(40) }
                    if let r = result {
                        summary(r)
                        if r.modules.count > 1 {
                            HStack(spacing: 8) {
                                ForEach(r.modules) { m in
                                    let on = m.type == (selected ?? r.modules.first?.type)
                                    Button { selected = m.type } label: {
                                        Text(m.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(on ? .white : Mn.ink2)
                                            .padding(.horizontal, 16).padding(.vertical, 9).background(on ? Mn.accent : Color.white.opacity(0.55), in: Capsule())
                                    }
                                }
                            }
                        }
                        if let m = r.modules.first(where: { $0.type == (selected ?? r.modules.first?.type) }) { moduleReview(m) }
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 12)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await load() }
        .task(id: result?.bands.writingPending == true) {
            // Writing is scored by AI in the background: refresh until the band arrives.
            guard result?.bands.writingPending == true else { return }
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            if !Task.isCancelled { await load() }
        }
    }

    private func load() async {
        error = nil
        do { result = try await API.shared.send(.get, "attempts/\(attemptId)/result") } catch { self.error = error.localizedDescription }
    }

    private func summary(_ r: ResultResponse) -> some View {
        let main = r.bands.overall ?? (r.modules.count == 1 ? r.modules[0].band : nil)
        return VStack(spacing: 16) {
            BandRing(value: main, size: 150, label: r.bands.overall != nil ? "OVERALL" : r.modules.first?.title.uppercased())
            HStack(spacing: 8) {
                ForEach(r.modules) { m in
                    VStack(spacing: 2) {
                        Text(m.title).font(.system(size: 12, weight: .semibold)).foregroundStyle(Mn.subtle)
                        Text(Fmt.band(m.band)).font(.system(size: 22, weight: .heavy)).foregroundStyle(Mn.ink)
                        Text(m.type == "writing" ? "AI baho" : "\(Int(m.correct ?? 0))/\(m.questions.reduce(0) { $0 + ($1.maxPoints ?? 1) })").font(.system(size: 12)).foregroundStyle(Mn.subtle)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 20))
                }
            }
            if r.bands.writingPending == true {
                Text("Writing AI tomonidan baholanmoqda — natija bir necha daqiqada chiqadi.").font(.system(size: 13)).foregroundStyle(Mn.subtle).multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity).padding(20).glass(radius: 28)
    }

    @ViewBuilder
    private func moduleReview(_ m: ResultModule) -> some View {
        if m.type == "writing" {
            ForEach(m.essays) { e in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Task \(e.task)").font(.system(size: 16, weight: .bold)).foregroundStyle(Mn.ink)
                        Spacer()
                        if let band = e.band { Pill(text: "Band \(Fmt.band(band))", bg: Mn.greenSoft, fg: Mn.green) } else { Pill(text: "Baholanmoqda…", bg: Mn.accentSoft, fg: Mn.accentDark) }
                    }
                    Text("\(e.words ?? 0) so'z").font(.system(size: 13)).foregroundStyle(Mn.subtle)
                    Text((e.answer ?? "").isEmpty ? "Javob yozilmagan." : e.answer!).font(.system(size: 14)).foregroundStyle(Mn.muted).lineLimit(12)
                    if let fb = e.feedback, !fb.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("AI izohi", systemImage: "sparkles").font(.system(size: 15, weight: .bold)).foregroundStyle(Color(hex: 0x3730A3))
                            Text(plainMarkdown(fb)).font(.system(size: 14)).foregroundStyle(Mn.muted)
                        }
                        .padding(14).frame(maxWidth: .infinity, alignment: .leading).background(Mn.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
                    }
                }
                .padding(18).glass()
            }
        } else {
            Text("\(m.title) javoblari" + (m.correct.map { " · \(Int($0)) / \(m.questions.reduce(0) { $0 + ($1.maxPoints ?? 1) })" } ?? ""))
                .font(.system(size: 15, weight: .bold)).foregroundStyle(Mn.ink)
            VStack(spacing: 0) {
                ForEach(m.questions) { q in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: q.isCorrect ? "checkmark" : "xmark").font(.system(size: 12, weight: .bold))
                            .foregroundStyle(q.isCorrect ? Mn.green : Mn.orange)
                            .frame(width: 26, height: 26).background(q.isCorrect ? Mn.greenSoft : Mn.orangeSoft, in: Circle())
                        Text((q.numberCount ?? 1) > 1 ? "\(q.number)–\(q.number + (q.numberCount ?? 1) - 1)" : "\(q.number)")
                            .font(.system(size: 14, weight: .bold)).foregroundStyle(Mn.ink).frame(width: 40, alignment: .leading).padding(.top, 3)
                        Group {
                            if q.isCorrect {
                                Text(q.yourAnswer ?? "")
                            } else {
                                Text("Sizniki: ") + Text(q.yourAnswer ?? "—").strikethrough(q.yourAnswer != nil) + Text("  ·  To'g'ri: ") + Text(q.correctAnswer ?? "").bold().foregroundColor(Mn.ink)
                            }
                        }
                        .font(.system(size: 14)).foregroundStyle(Mn.muted).padding(.top, 3)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 9)
                }
            }
            .padding(.vertical, 6).glass()
        }
    }

    private func plainMarkdown(_ text: String) -> String {
        text.split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.drop(while: { $0 == "#" || $0 == " " }).replacingOccurrences(of: "**", with: "") }
            .joined(separator: "\n")
    }
}
