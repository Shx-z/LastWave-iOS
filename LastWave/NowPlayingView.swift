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
                VStack(spacing: 18) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.down").font(.system(size: 18, weight: .semibold)).foregroundStyle(LW.fg)
                                .frame(width: 44, height: 44)
                        }
                        Spacer()
                        Text(Catalog.albumTitle(t.albumId)).font(.system(size: 13, weight: .semibold)).foregroundStyle(LW.muted)
                        Spacer()
                        Button { player.toggleLike(t.id) } label: {
                            Image(systemName: player.liked.contains(t.id) ? "heart.fill" : "heart")
                                .foregroundStyle(player.liked.contains(t.id) ? Color(hex: "c45c5c") : LW.fg)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal, 8)

                    if player.lyricsOpen {
                        LyricsView(track: t)
                            .frame(maxHeight: .infinity)
                    } else {
                        CoverView(color: t.color, title: t.title, corner: 24)
                            .aspectRatio(1, contentMode: .fit)
                            .padding(.horizontal, 28)
                            .shadow(color: .black.opacity(0.4), radius: 30, y: 16)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(t.title).font(.system(size: 24, weight: .semibold)).foregroundStyle(LW.fg)
                        Text(Catalog.artistName(t.artistId)).font(.system(size: 16)).foregroundStyle(LW.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)

                    VStack(spacing: 6) {
                        Slider(value: Binding(
                            get: { player.currentTime },
                            set: { player.seek($0) }
                        ), in: 0...max(player.duration, 1))
                        .tint(LW.accent)
                        HStack {
                            Text(formatTime(player.currentTime)).font(.caption.monospacedDigit()).foregroundStyle(LW.muted)
                            Spacer()
                            Text(t.quality).font(.caption).foregroundStyle(LW.tint)
                            Spacer()
                            Text(formatTime(player.duration)).font(.caption.monospacedDigit()).foregroundStyle(LW.muted)
                        }
                    }
                    .padding(.horizontal, 28)

                    HStack(spacing: 28) {
                        Button { player.shuffle.toggle() } label: {
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

                    HStack {
                        Button { player.lyricsOpen.toggle() } label: {
                            Label("Lyrics", systemImage: "quote.opening")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(player.lyricsOpen ? LW.bg : LW.fg)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(Capsule().fill(player.lyricsOpen ? LW.accent : LW.elevated))
                        }
                        Spacer()
                        Text("Hi-Res").font(.system(size: 12, weight: .semibold)).foregroundStyle(LW.muted)
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 12)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct LyricsView: View {
    @EnvironmentObject var player: Player
    let track: Track

    var active: Int {
        let t = player.currentTime
        var idx = 0
        for (i, line) in track.lyrics.enumerated() {
            if line.t <= t { idx = i }
        }
        return idx
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(Array(track.lyrics.enumerated()), id: \.offset) { i, line in
                        Text(line.text)
                            .font(.system(size: i == active ? 28 : 22, weight: i == active ? .semibold : .regular))
                            .foregroundStyle(i == active ? LW.fg : LW.muted.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(i)
                            .scaleEffect(i == active ? 1.0 : 0.96, anchor: .leading)
                            .animation(.easeOut(duration: 0.25), value: active)
                    }
                }
                .padding(.horizontal, 28)
            }
            .onChange(of: active) { _, n in
                withAnimation { proxy.scrollTo(n, anchor: .center) }
            }
        }
    }
}
