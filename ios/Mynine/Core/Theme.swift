import SwiftUI

/// Liquid glass tokens (web resources/css/app.css, design canvas "Mynine Mobile"), same as the Android app.
enum Mn {
    static let bg = Color(hex: 0xEEF1F8)
    static let ink = Color(hex: 0x0F172A)
    static let ink2 = Color(hex: 0x1E293B)
    static let muted = Color(hex: 0x334155)
    static let subtle = Color(hex: 0x475569)
    static let accent = Color(hex: 0x4F46E5)
    static let accentDark = Color(hex: 0x4338CA)
    static let accentSoft = Color(hex: 0x4F46E5, alpha: 0.10)
    static let indigo = Color(hex: 0x818CF8)
    static let sky = Color(hex: 0x38BDF8)
    static let pink = Color(hex: 0xF472B6)
    static let green = Color(hex: 0x047857)
    static let greenSoft = Color(hex: 0x10B981, alpha: 0.15)
    static let orange = Color(hex: 0xC2410C)
    static let orangeSoft = Color(hex: 0xEA580C, alpha: 0.14)
    static let red = Color(hex: 0xB91C1C)
    static let glassEdge = Color.white.opacity(0.75)

    // Exam room (official IELTS white UI)
    static let examRed = Color(hex: 0xE11D48)
    static let examBlue = Color(hex: 0x2563EB)
    static let examLine = Color(hex: 0xD1D5DB)
    static let examPanel = Color(hex: 0xF3F4F6)
    static let examText = Color(hex: 0x111827)
    static let examTimer = Color(hex: 0xDC2626)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255, opacity: alpha)
    }
}

/// Soft coloured orbs behind the glass.
struct GlassBackground: View {
    var variant = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                Mn.bg
                let spots: [(Color, CGFloat, CGFloat)] = switch variant % 3 {
                case 0: [(Mn.indigo, -60, -80), (Mn.sky, w - 80, 320), (Mn.pink, 60, 680)]
                case 1: [(Mn.indigo, w - 60, -60), (Mn.sky, -60, 420), (Mn.pink, w - 120, 700)]
                default: [(Mn.pink, -20, -40), (Mn.indigo, w - 40, 20), (Mn.sky, 80, 680)]
                }
                ForEach(Array(spots.enumerated()), id: \.offset) { _, spot in
                    Circle()
                        .fill(spot.0.opacity(0.5))
                        .frame(width: 320, height: 320)
                        .blur(radius: 70)
                        .position(x: spot.1 + 100, y: spot.2 + 100)
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct Glass: ViewModifier {
    var radius: CGFloat = 24
    var strong = false

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial.opacity(strong ? 1 : 0.9), in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .background(Color.white.opacity(strong ? 0.55 : 0.35), in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Mn.glassEdge, lineWidth: 1))
    }
}

extension View {
    func glass(radius: CGFloat = 24, strong: Bool = false) -> some View { modifier(Glass(radius: radius, strong: strong)) }
}

struct PrimaryButton: View {
    let title: String
    var loading = false
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if loading { ProgressView().tint(.white) } else { Text(title).font(.system(size: 16, weight: .bold)) }
            }
            .frame(maxWidth: .infinity, minHeight: 54)
            .foregroundStyle(.white)
            .background(enabled ? Mn.accent : Color.gray.opacity(0.35), in: Capsule())
            .shadow(color: enabled ? Mn.accent.opacity(0.35) : .clear, radius: 12, y: 8)
        }
        .disabled(!enabled || loading)
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String?
    /// Asset catalog image kept in its own colours (brand marks).
    var image: String?
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let image { Image(image).resizable().scaledToFit().frame(width: 20, height: 20) } else if let systemImage { Image(systemName: systemImage) }
                Text(title).font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(Mn.ink)
            .background(Color.white, in: Capsule())
            .overlay(Capsule().stroke(Color(hex: 0xE2E8F0)))
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.6)
    }
}

struct Pill: View {
    let text: String
    var bg: Color = Color.white.opacity(0.85)
    var fg: Color = Mn.ink2

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(fg)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(bg, in: Capsule())
    }
}

struct ErrorCard: View {
    let message: String
    var retry: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(message).foregroundStyle(Mn.muted).font(.system(size: 15))
            if let retry {
                Button("Qayta urinish", action: retry).font(.system(size: 15, weight: .semibold)).foregroundStyle(Mn.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glass()
    }
}

struct ScreenTitle: View {
    let text: String
    var body: some View {
        Text(text).font(.system(size: 30, weight: .heavy)).foregroundStyle(Mn.ink).tracking(-0.6)
    }
}

enum Fmt {
    static func band(_ value: Double?) -> String {
        guard let value else { return "–" }
        return String(format: "%.1f", value)
    }

    static func module(_ type: String) -> String {
        switch type {
        case "listening": return "Listening"
        case "reading": return "Reading"
        case "writing": return "Writing"
        default: return type.capitalized
        }
    }

    static func minutes(_ seconds: Int) -> String {
        let m = (seconds + 59) / 60
        if m >= 60 { return "\(m / 60) soat" + (m % 60 > 0 ? " \(m % 60) daq" : "") }
        return "\(m) daq"
    }

    static func shortDate(_ iso: String?) -> String {
        guard let iso, iso.count >= 10 else { return "" }
        let months = ["yan", "fev", "mar", "apr", "may", "iyun", "iyul", "avg", "sen", "okt", "noy", "dek"]
        let parts = iso.prefix(10).split(separator: "-")
        guard parts.count == 3, let m = Int(parts[1]), let d = Int(parts[2]) else { return String(iso.prefix(10)) }
        return "\(d)-\(months[max(0, min(11, m - 1))])"
    }
}

struct Avatar: View {
    let name: String
    var size: CGFloat = 44

    var body: some View {
        Text(String(name.trimmingCharacters(in: .whitespaces).first ?? "M").uppercased())
            .font(.system(size: size * 0.38, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(LinearGradient(colors: [Color(hex: 0x6366F1), Color(hex: 0xEC4899)], startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
    }
}

struct BandRing: View {
    let value: Double?
    var size: CGFloat = 92
    var label: String?

    var body: some View {
        ZStack {
            Circle().stroke(Mn.accent.opacity(0.15), lineWidth: size * 0.11)
            Circle()
                .trim(from: 0, to: CGFloat((value ?? 0) / 9))
                .stroke(Mn.accent, style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                if let label { Text(label).font(.system(size: 11, weight: .bold)).foregroundStyle(Mn.subtle).tracking(1) }
                Text(Fmt.band(value)).font(.system(size: size * 0.28, weight: .heavy)).foregroundStyle(Mn.ink)
            }
        }
        .frame(width: size, height: size)
        .padding(size * 0.055)
    }
}
