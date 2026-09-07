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
                    genreCard
                    albums
                    liveRow
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
            .task { if player.trending.isEmpty { await player.loadTrending() } }
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
        .padding(.top, 4)
    }

    var albums: some View {
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

    var liveRow: some View {
        Group {
            if !player.trending.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Streaming now").font(.system(size: 20, weight: .semibold)).foregroundStyle(LW.fg)
                        Spacer()
                        Text("Live").font(.caption.weight(.semibold)).foregroundStyle(LW.tint)
                    }
                    .padding(.horizontal, 16)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(player.trending.prefix(16)) { t in
                                Button { player.play(t.id, queue: player.trending.map(\.id)) } label: {
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
                .padding(.top, 8)
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
        else if key.hasPrefix("album:") { AlbumView(id: String(key.dropFirst(6))) }
        else if key.hasPrefix("artist:") { ArtistView(id: String(key.dropFirst(7))) }
        else if key.hasPrefix("playlist:") { PlaylistView(id: String(key.dropFirst(9))) }
        else if key.hasPrefix("friend:") { FriendView(id: String(key.dropFirst(7))) }
        else if key.hasPrefix("genre:") {
            let g = String(key.dropFirst(6))
            GenreTracksView(genre: g)
        }
        else { Text("Missing").foregroundStyle(LW.muted) }
    }
}
