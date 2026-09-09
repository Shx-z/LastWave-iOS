import AVKit
import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var player: Player
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            LW.bg.ignoresSafeArea()
            if let t = player.current {
                LinearGradient(colors: [Color(hex: t.color).opacity(0.45), LW.bg], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.down").font(.system(size: 18, weight: .semibold)).foregroundStyle(LW.fg)
                                .frame(width: 44, height: 44)
                        }
                        Spacer()
                        VStack(spacing: 2) {
                            Text("NOW PLAYING").font(.system(size: 11, weight: .semibold)).tracking(1.6).foregroundStyle(LW.muted)
                            Text(Catalog.albumTitle(t.albumId)).font(.system(size: 13, weight: .semibold)).foregroundStyle(LW.fg.opacity(0.85))
                        }
                        Spacer()
                        Menu {
                            Button { player.toggleLike(t.id) } label: { Label(player.liked.contains(t.id) ? "Unlike" : "Love", systemImage: "heart") }
                            Button { player.toggleDownload(t.id) } label: { Label(player.isOffline(t.id) ? "Remove download" : "Download for offline", systemImage: "arrow.down.circle") }
                            Button { player.queueOpen = true } label: { Label("Play queue", systemImage: "list.bullet") }
                            Menu("Sleep timer") {
                                Button("Off") { player.setSleep(nil) }
                                ForEach([5, 15, 30, 45, 60], id: \.self) { m in
                                    Button("\(m) min") { player.setSleep(m) }
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis").foregroundStyle(LW.fg).frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal, 8)

                    if player.lyricsOpen {
                        LyricsView(track: t).frame(maxHeight: .infinity)
                    } else {
                        CoverView(color: t.color, title: t.title, corner: 24, artworkURL: t.artworkURL)
                            .aspectRatio(1, contentMode: .fit)
                            .padding(.horizontal, 28)
                            .shadow(color: .black.opacity(0.4), radius: 30, y: 16)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(t.title).font(.system(size: 24, weight: .semibold)).foregroundStyle(LW.fg)
                            Spacer()
                            Button { player.toggleLike(t.id) } label: {
                                Image(systemName: player.liked.contains(t.id) ? "heart.fill" : "heart")
                                    .foregroundStyle(player.liked.contains(t.id) ? Color(hex: "c45c5c") : LW.fg)
                            }
                        }
                        Text(t.displayArtist).font(.system(size: 16)).foregroundStyle(LW.muted)
                    }
                    .padding(.horizontal, 28)

                    VStack(spacing: 6) {
                        WavySeek(
                            value: Binding(get: { player.currentTime }, set: { player.seek($0) }),
                            maxValue: max(player.duration, 1),
                            color: Color(hex: t.color).opacity(0.95).blended(with: LW.accent),
                            playing: player.playing
                        )
                        HStack {
                            Text(formatTime(player.currentTime)).font(.caption.monospacedDigit()).foregroundStyle(LW.muted)
                            Spacer()
                            Text(player.qualityBadge).font(.caption.weight(.semibold)).foregroundStyle(LW.tint)
                            Spacer()
                            Text(formatTime(player.duration)).font(.caption.monospacedDigit()).foregroundStyle(LW.muted)
                        }
                    }
                    .padding(.horizontal, 28)

                    HStack(spacing: 26) {
                        Button { player.shuffle.toggle(); player.persist() } label: {
                            Image(systemName: "shuffle").foregroundStyle(player.shuffle ? LW.tint : LW.muted).frame(width: 44, height: 44)
                        }
                        Button { player.prev() } label: {
                            Image(systemName: "backward.fill").font(.system(size: 22)).foregroundStyle(LW.fg).frame(width: 44, height: 44)
                        }
                        Button { player.toggle() } label: {
                            Image(systemName: player.playing ? "pause.fill" : "play.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(LW.bg)
                                .frame(width: 72, height: 72)
                                .background(Circle().fill(LW.accent))
                        }
                        Button { player.next() } label: {
                            Image(systemName: "forward.fill").font(.system(size: 22)).foregroundStyle(LW.fg).frame(width: 44, height: 44)
                        }
                        Button { player.cycleRepeat() } label: {
                            Image(systemName: player.repeatMode == .one ? "repeat.1" : "repeat")
                                .foregroundStyle(player.repeatMode == .off ? LW.muted : LW.tint)
                                .frame(width: 44, height: 44)
                        }
                    }

                    HStack(spacing: 12) {
                        Button { player.lyricsOpen.toggle() } label: {
                            Label("Lyrics", systemImage: "quote.opening")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(player.lyricsOpen ? LW.bg : LW.fg)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(Capsule().fill(player.lyricsOpen ? LW.accent : LW.elevated))
                        }
                        Button { player.queueOpen = true } label: {
                            Image(systemName: "list.bullet").foregroundStyle(LW.fg)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(LW.elevated))
                        }
                        Button { player.lyricsFull = true } label: {
                            Text("Full")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(LW.fg)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(Capsule().fill(LW.elevated))
                        }
                        RoutePicker()
                            .frame(width: 40, height: 40)
                        if let m = player.sleepMinutes {
                            Text("\(m)m").font(.caption.weight(.semibold)).foregroundStyle(LW.tint)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 10)
                }
            }
        }
        .buttonStyle(.plain)
        .onChange(of: player.lyricsOpen) { _, on in
            if on, let id = player.currentId { Task { await player.fetchLyricsIfNeeded(id) } }
        }
        .sheet(isPresented: $player.queueOpen) {
            QueueView().environmentObject(player).presentationDetents([.medium, .large]).preferredColorScheme(.dark)
        }
        .fullScreenCover(isPresented: $player.lyricsFull) {
            if let t = player.current {
                FullscreenLyrics(track: t).environmentObject(player).preferredColorScheme(.dark)
            }
        }
    }
}

struct RoutePicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let v = AVRoutePickerView()
        v.tintColor = UIColor(white: 0.95, alpha: 1)
        v.activeTintColor = UIColor(red: 0.54, green: 0.63, blue: 0.67, alpha: 1)
        return v
    }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

extension Color {
    func blended(with other: Color) -> Color { self }
}

struct LyricsView: View {
    @EnvironmentObject var player: Player
    let track: Track

    var active: Int {
        var idx = 0
        for (i, line) in track.lyrics.enumerated() where line.t <= player.currentTime { idx = i }
        return idx
    }

    var words: [(t: Double, text: String, line: Int)] {
        var out: [(t: Double, text: String, line: Int)] = []
        for (i, line) in track.lyrics.enumerated() {
            let parts = line.text.split(separator: " ").map(String.init)
            guard !parts.isEmpty else { continue }
            let nextT = i + 1 < track.lyrics.count ? track.lyrics[i + 1].t : line.t + 4
            let span = max(0.25, nextT - line.t)
            for (j, w) in parts.enumerated() {
                out.append((line.t + span * Double(j) / Double(parts.count), w, i))
            }
        }
        return out
    }

    var activeWord: Int {
        var idx = 0
        for (i, w) in words.enumerated() where w.t <= player.currentTime { idx = i }
        return idx
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: player.lyricsStyle == .kineticSlide ? 22 : 18) {
                    ForEach(Array(track.lyrics.enumerated()), id: \.offset) { i, line in
                        let on = i == active
                        let rtl = line.text.contains(where: { $0.unicodeScalars.contains(where: { $0.value >= 0x0600 && $0.value <= 0x06FF || $0.value >= 0x0590 && $0.value <= 0x05FF }) })
                        Group {
                            if (player.lyricsStyle == .wordSpotlight || player.lyricsStyle == .rtlCascade), on {
                                wordLine(i, rtl: rtl || player.lyricsStyle == .rtlCascade)
                            } else {
                                Text(line.text)
                                    .font(.system(size: on ? 28 : 22, weight: on ? .semibold : .regular))
                                    .foregroundStyle(on ? LW.fg : LW.muted.opacity(player.lyricsStyle == .karaokePulse ? 0.38 : 0.7))
                                    .environment(\.layoutDirection, rtl ? .rightToLeft : .leftToRight)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id(i)
                        .scaleEffect(on && (player.lyricsStyle == .appleFluid || player.lyricsStyle == .pulseWave) ? 1.04 : (on ? 1.0 : 0.96), anchor: .leading)
                        .offset(x: player.lyricsStyle == .kineticSlide && !on ? 12 : 0)
                        .opacity(player.lyricsStyle == .driftFade && i < active ? 0.3 : (player.lyricsStyle == .kineticSlide && i > active + 4 ? 0.35 : 1))
                        .animation(.easeOut(duration: 0.28), value: active)
                    }
                }
                .padding(.horizontal, 28)
            }
            .onChange(of: active) { _, n in
                withAnimation { proxy.scrollTo(n, anchor: .center) }
            }
        }
    }

    func wordLine(_ i: Int, rtl: Bool) -> some View {
        let lineWords = words.filter { $0.line == i }
        return HStack(spacing: 6) {
            ForEach(Array(lineWords.enumerated()), id: \.offset) { j, w in
                let global = words.firstIndex(where: { $0.t == w.t && $0.text == w.text }) ?? 0
                Text(w.text)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(global <= activeWord ? LW.fg : LW.muted.opacity(0.45))
            }
        }
        .environment(\.layoutDirection, rtl ? .rightToLeft : .leftToRight)
    }
}

struct FullscreenLyrics: View {
    @EnvironmentObject var player: Player
    let track: Track
    var active: Int {
        var idx = 0
        for (i, line) in track.lyrics.enumerated() where line.t <= player.currentTime { idx = i }
        return idx
    }
    var body: some View {
        ZStack(alignment: .topTrailing) {
            LW.bg.ignoresSafeArea()
            Button { player.lyricsFull = false } label: {
                Image(systemName: "xmark").foregroundStyle(LW.fg).frame(width: 44, height: 44)
            }
            .padding()
            let line = track.lyrics.indices.contains(active) ? track.lyrics[active].text : "…"
            Text(line)
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(LW.fg)
                .multilineTextAlignment(.center)
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct QueueView: View {
    @EnvironmentObject var player: Player
    var body: some View {
        NavigationStack {
            List {
                ForEach(player.queue, id: \.self) { id in
                    Button { player.play(id, queue: player.queue) } label: {
                        HStack {
                            if let t = Catalog.track(id) {
                                CoverView(color: t.color, title: t.title, corner: 6, artworkURL: t.artworkURL).frame(width: 40, height: 40)
                                VStack(alignment: .leading) {
                                    Text(t.title).foregroundStyle(player.currentId == id ? LW.tint : LW.fg)
                                    Text(t.displayArtist).font(.caption).foregroundStyle(LW.muted)
                                }
                            }
                            Spacer()
                            if player.currentId == id {
                                Image(systemName: player.playing ? "waveform" : "pause.fill").foregroundStyle(LW.tint)
                            }
                        }
                    }
                    .listRowBackground(LW.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(LW.bg)
            .navigationTitle("Play queue")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { player.queueOpen = false }
                }
            }
        }
    }
}
