import SwiftUI

struct HomeView: View {
    @EnvironmentObject var player: Player
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    stats
                    scrobbleHero
                    genreCard
                    listenAgain
                    quickPicks
                    albumsForYou
                    newReleases
                    filterBar
                    VStack(spacing: 0) {
                        ForEach(player.listIds, id: \.self) { id in
                            TrackRow(id: id, queue: player.listIds)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .background(LW.bg)
            .navigationBarHidden(true)
            .task {
                if player.trending.isEmpty { await player.loadTrending() }
                if player.releases.isEmpty { await player.loadMoreReleases() }
            }
            .navigationDestination(for: String.self) { key in
                dest(key)
            }
        }
    }

    var header: some View {
        HStack(spacing: 10) {
            Text("LastWave")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(LW.fg)
            Spacer()
            navBtn("safari") { path.append("discover") }
            navBtn("magnifyingglass") { path.append("search") }
            Button { path.append("friends") } label: {
                Circle().fill(LW.chip).frame(width: 44, height: 44)
                    .overlay(Text(String(Catalog.profileName.prefix(1))).font(.headline).foregroundStyle(LW.fg))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    var stats: some View {
        HStack {
            Button { path.append("friends") } label: {
                Text("@\(Catalog.profileHandle)")
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Capsule().fill(LW.elevated))
                    .foregroundStyle(LW.fg)
            }.buttonStyle(.plain)
            Spacer()
            let d = player.listenedSeconds / 86400
            let h = (player.listenedSeconds % 86400) / 3600
            Text("\(d)d \(h)h")
                .font(.system(size: 13))
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Capsule().fill(LW.elevated))
                .foregroundStyle(LW.muted)
        }
        .padding(.horizontal, 16)
    }

    var scrobbleHero: some View {
        VStack(spacing: 8) {
            Button { path.append("friends") } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(player.scrobbles.formatted())
                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                            .foregroundStyle(LW.fg)
                        Text("Scrobbles").font(.system(size: 14)).foregroundStyle(LW.muted)
                    }
                    Spacer()
                    Circle().fill(LW.accent).frame(width: 44, height: 44)
                        .overlay(Image(systemName: "chevron.right").foregroundStyle(LW.bg))
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: "2a3940")))
            }
            .buttonStyle(.plain)
            HStack(spacing: 8) {
                statChip("\(Catalog.tracks.count + player.trending.count)", "Tracks")
                statChip("\(Catalog.artists.count)", "Artists")
                statChip("\(Catalog.albums.count)", "Albums")
            }
        }
        .padding(.horizontal, 16)
    }

    func statChip(_ n: String, _ l: String) -> some View {
        VStack(spacing: 2) {
            Text(n).font(.system(size: 18, weight: .semibold)).foregroundStyle(LW.fg)
            Text(l).font(.system(size: 11)).foregroundStyle(LW.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(LW.elevated))
    }

    var genreCard: some View {
        Button { path.append("genres") } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Genre DNA").font(.system(size: 18, weight: .semibold)).foregroundStyle(LW.fg)
                    Text("From your scrobbles").font(.system(size: 13)).foregroundStyle(LW.muted)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(LW.muted)
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(LW.chip))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    var listenAgain: some View {
        rail("Listen again", tracks: player.recent.compactMap(Catalog.track), live: false)
    }

    var quickPicks: some View {
        rail("Quick picks", tracks: Array((player.trending.isEmpty ? Catalog.tracks : player.trending).prefix(12)), live: true)
    }

    func rail(_ title: String, tracks: [Track], live: Bool) -> some View {
        Group {
            if !tracks.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(title).font(.system(size: 20, weight: .semibold)).foregroundStyle(LW.fg)
                        Spacer()
                        if live { Text("Live").font(.caption.weight(.semibold)).foregroundStyle(LW.tint) }
                    }
                    .padding(.horizontal, 16)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(tracks.prefix(16)) { t in
                                Button { player.play(t.id, queue: tracks.map(\.id)) } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        CoverView(color: t.color, title: t.title, corner: 12, artworkURL: t.artworkURL)
                                            .frame(width: 132, height: 132)
                                        Text(t.title).font(.system(size: 13, weight: .semibold)).foregroundStyle(LW.fg).lineLimit(1)
                                        Text(t.displayArtist).font(.system(size: 12)).foregroundStyle(LW.muted).lineLimit(1)
                                    }
                                    .frame(width: 132)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
    }

    var albumsForYou: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Albums for you").font(.system(size: 20, weight: .semibold)).foregroundStyle(LW.fg).padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Catalog.albums) { a in
                        Button { path.append("album:\(a.id)") } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                CoverView(color: a.color, title: a.title, corner: 12)
                                    .frame(width: 132, height: 132)
                                Text(a.title).font(.system(size: 13, weight: .semibold)).foregroundStyle(LW.fg).lineLimit(1)
                                Text(Catalog.artistName(a.artistId)).font(.system(size: 12)).foregroundStyle(LW.muted).lineLimit(1)
                            }
                            .frame(width: 132)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    var newReleases: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("New releases").font(.system(size: 20, weight: .semibold)).foregroundStyle(LW.fg)
                Spacer()
                Text("Live").font(.caption.weight(.semibold)).foregroundStyle(LW.tint)
            }
            .padding(.horizontal, 16)
            let list = player.releases.isEmpty ? player.trending : player.releases
            ForEach(list.prefix(8)) { t in
                TrackRow(id: t.id, queue: list.map(\.id))
            }
            if !player.releasesDone {
                Button {
                    Task { await player.loadMoreReleases() }
                } label: {
                    Text("Load more")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(LW.fg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 16).fill(LW.elevated))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
            }
        }
    }

    var filterBar: some View {
        HStack {
            Text("Listening").font(.system(size: 20, weight: .semibold)).foregroundStyle(LW.fg)
            Spacer()
            Menu {
                ForEach(ListFilter.allCases, id: \.self) { f in
                    Button(f.rawValue.capitalized) { player.listFilter = f }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(player.listFilter.rawValue.capitalized)
                    Image(systemName: "chevron.down").font(.system(size: 11, weight: .semibold))
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(LW.fg)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Capsule().fill(LW.elevated))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    func navBtn(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(LW.fg)
                .frame(width: 44, height: 44)
                .background(Circle().fill(LW.elevated))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func dest(_ key: String) -> some View {
        if key == "search" { SearchView() }
        else if key == "discover" { DiscoverView() }
        else if key == "genres" { GenresView() }
        else if key == "friends" { FriendsView() }
        else if key == "settings" { SettingsView() }
        else if key == "downloads" { DownloadsView() }
        else if key.hasPrefix("album:") { AlbumView(id: String(key.dropFirst(6))) }
        else if key.hasPrefix("artist:") { ArtistView(id: String(key.dropFirst(7))) }
        else if key.hasPrefix("playlist:") { PlaylistView(id: String(key.dropFirst(9))) }
        else if key.hasPrefix("friend:") { FriendView(id: String(key.dropFirst(7))) }
        else if key.hasPrefix("genre:") { GenreTracksView(genre: String(key.dropFirst(6))) }
        else { Text("Missing").foregroundStyle(LW.muted) }
    }
}
