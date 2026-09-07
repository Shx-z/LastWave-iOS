import SwiftUI

struct WavySeek: View {
    @Binding var value: Double
    var maxValue: Double
    var color: Color = LW.accent
    var playing: Bool = true

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let mid = h / 2
            let ratio = maxValue > 0 ? min(1, max(0, value / maxValue)) : 0
            let played = ratio * w
            Canvas { ctx, size in
                var rest = Path()
                rest.move(to: CGPoint(x: 0, y: mid))
                rest.addLine(to: CGPoint(x: w, y: mid))
                ctx.stroke(rest, with: .color(.white.opacity(0.18)), style: StrokeStyle(lineWidth: 2, lineCap: .round))

                var wave = Path()
                let step: CGFloat = 2
                var x: CGFloat = 0
                while x <= played {
                    let amp: CGFloat = (playing ? 6.2 : 2.2) * (0.35 + 0.65 * sin((x / max(w, 1)) * .pi))
                    let y = mid + sin(x * 0.42) * amp
                    if x == 0 { wave.move(to: CGPoint(x: x, y: y)) }
                    else { wave.addLine(to: CGPoint(x: x, y: y)) }
                    x += step
                }
                ctx.stroke(wave, with: .color(color), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        let p = min(1, max(0, g.location.x / max(w, 1)))
                        value = p * max(maxValue, 1)
                    }
            )
        }
        .frame(height: 28)
        .animation(.easeOut(duration: 0.15), value: playing)
    }
}
