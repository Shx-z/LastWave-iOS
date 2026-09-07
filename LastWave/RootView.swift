import SwiftUI

enum Tab: Hashable { case home, create, playlists }

struct RootView: View {
    @EnvironmentObject var player: Player
    @State private var tab: Tab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            LW.bg.ignoresSafeArea()
            Group {
                switch tab {
                case .home: HomeView()
                case .create: GenerateView()
                case .playlists: LibraryView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, player.current == nil ? 84 : 148)

            VStack(spacing: 10) {
                if player.current != nil { MiniPlayer() }
                TabBar(tab: $tab)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $player.playerOpen) {
            NowPlayingView()
                .environmentObject(player)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .preferredColorScheme(.dark)
        }
    }
}

struct TabBar: View {
    @EnvironmentObject var player: Player
    @Binding var tab: Tab

    var body: some View {
        HStack(spacing: 6) {
            pill(.home, "Home", "house.fill")
            pill(.create, "Create", "plus")
            pill(.playlists, "Playlists", "music.note.list")
        }
        .padding(6)
        .background {
            Capsule(style: .continuous)
                .fill(player.liquidGlass ? .ultraThinMaterial : Material.bar)
                .overlay(Capsule().stroke(.white.opacity(0.08)))
                .shadow(color: .black.opacity(0.45), radius: 20, y: 8)
        }
    }

    @ViewBuilder
    func pill(_ t: Tab, _ label: String, _ icon: String) -> some View {
        let on = tab == t
        Button {
            tab = t
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 17, weight: .semibold))
                if on { Text(label).font(.system(size: 13, weight: .semibold)) }
            }
            .foregroundStyle(on ? LW.fg : LW.muted)
            .frame(minWidth: on ? 96 : 44, minHeight: 44)
            .padding(.horizontal, on ? 12 : 0)
            .background {
                if on { Capsule().fill(LW.chip) }
            }
        }
        .buttonStyle(.plain)
    }
}

struct MiniPlayer: View {
    @EnvironmentObject var player: Player

    var body: some View {
        if let t = player.current {
            Button { player.playerOpen = true } label: {
                HStack(spacing: 12) {
                    CoverView(color: t.color, title: t.title, corner: 8, artworkURL: t.artworkURL)
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(LW.fg).lineLimit(1)
                        Text(t.displayArtist).font(.system(size: 12)).foregroundStyle(LW.muted).lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    Button {
                        player.toggle()
                    } label: {
                        Image(systemName: player.playing ? "pause.fill" : "play.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(LW.fg)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.leading, 8)
                .padding(.trailing, 4)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(player.liquidGlass ? .ultraThinMaterial : Material.bar)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.08)))
                }
            }
            .buttonStyle(.plain)
        }
    }
}

struct TrackRow: View {
    @EnvironmentObject var player: Player
    let id: String
    var queue: [String]? = nil

    var body: some View {
        if let t = Catalog.track(id) {
            Button {
                player.play(id, queue: queue ?? (player.trending.map(\.id) + Catalog.tracks.map(\.id)))
            } label: {
                HStack(spacing: 12) {
                    CoverView(color: t.color, title: t.title, corner: 8, artworkURL: t.artworkURL)
                        .frame(width: 48, height: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t.title)
                            .font(.system(size: 16, weight: player.currentId == id ? .semibold : .regular))
                            .foregroundStyle(player.currentId == id ? LW.tint : LW.fg)
                            .lineLimit(1)
                        Text("\(t.displayArtist) · \(t.quality)")
                            .font(.system(size: 12))
                            .foregroundStyle(LW.muted)
                            .lineLimit(1)
                    }
                    Spacer()
                    if player.downloading.contains(id) {
                        ProgressView().tint(LW.accent).frame(width: 36, height: 44)
                    } else if player.isOffline(id) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(LW.tint)
                    }
                    Button {
                        player.toggleLike(id)
                    } label: {
                        Image(systemName: player.liked.contains(id) ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundStyle(player.liked.contains(id) ? Color(hex: "c45c5c") : LW.muted)
                            .frame(width: 36, height: 44)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button { player.toggleLike(id) } label: { Label(player.liked.contains(id) ? "Unlike" : "Love", systemImage: "heart") }
                Button { player.toggleDownload(id) } label: { Label(player.isOffline(id) ? "Remove download" : "Download for offline", systemImage: "arrow.down.circle") }
                ForEach(player.playlists) { p in
                    Button { player.addToPlaylist(p.id, track: id) } label: { Label("Add to \(p.title)", systemImage: "plus") }
                }
            }
        }
    }
}

struct PlayAllButton: View {
    @EnvironmentObject var player: Player
    let ids: [String]
    var body: some View {
        Button {
            if let first = ids.first { player.play(first, queue: ids) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                Text("Play all")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(LW.bg)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(LW.accent))
        }
        .buttonStyle(.plain)
    }
}
