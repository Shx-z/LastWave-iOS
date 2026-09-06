import SwiftUI

enum LW {
    static let bg = Color(red: 0.020, green: 0.020, blue: 0.024)
    static let surface = Color(red: 0.078, green: 0.078, blue: 0.086)
    static let elevated = Color(red: 0.110, green: 0.110, blue: 0.122)
    static let chip = Color(red: 0.149, green: 0.149, blue: 0.165)
    static let fg = Color(red: 0.957, green: 0.957, blue: 0.965)
    static let muted = Color(red: 0.557, green: 0.557, blue: 0.588)
    static let accent = Color(red: 0.835, green: 0.847, blue: 0.878)
    static let tint = Color(red: 0.541, green: 0.627, blue: 0.667)
}

extension Color {
    init(hex: String) {
        var h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if h.count == 3 { h = h.map { "\($0)\($0)" }.joined() }
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        self.init(
            red: Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8) & 0xFF) / 255,
            blue: Double(int & 0xFF) / 255
        )
    }
}

struct CoverView: View {
    let color: String
    let title: String
    var corner: CGFloat = 10

    var body: some View {
        let c = Color(hex: color)
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [c.opacity(0.95), Color.black.opacity(0.72), c.opacity(0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .bottomLeading) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(2)
                    .padding(8)
            }
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            )
            .clipped()
    }
}

func formatTime(_ t: Double) -> String {
    guard t.isFinite, t >= 0 else { return "0:00" }
    let s = Int(t)
    return String(format: "%d:%02d", s / 60, s % 60)
}

func formatCompact(_ n: Int) -> String {
    if n >= 1000 { return String(format: "%.1fK", Double(n) / 1000) }
    return "\(n)"
}
