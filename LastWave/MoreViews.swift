import SwiftUI

struct GenerateView: View {
    @EnvironmentObject var player: Player

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Create")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(LW.fg)
                .padding(.top, 12)
            Text("Build a taste mix from loves, recents, and the room's color.")
                .foregroundStyle(LW.muted)
            if player.generating {
                VStack(alignment: .leading, spacing: 10) {
                    Text(player.generateLabel).foregroundStyle(LW.fg)
                    ProgressView(value: player.generateProgress)
                        .tint(LW.accent)
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 16).fill(LW.elevated))
            } else {
                Button { player.generateMix() } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Generate taste mix")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(LW.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(LW.accent))
                }
                .buttonStyle(.plain)
            }
            Text("Recent mixes").font(.headline).foregroundStyle(LW.fg).padding(.top, 8)
            ForEach(player.playlists.filter(\.generated)) { p in
                HStack(spacing: 12) {
                    CoverView(color: p.color, title: p.title, corner: 10).frame(width: 56, height: 56)
                    VStack(alignment: .leading) {
                        Text(p.title).foregroundStyle(LW.fg)
                        Text(p.subtitle).font(.caption).foregroundStyle(LW.muted)
                    }
                    Spacer()
                    if let first = p.trackIds.first {
                        Button { player.play(first, queue: p.trackIds) } label: {
                            Image(systemName: "play.fill").foregroundStyle(LW.fg).frame(width: 44, height: 44)
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(LW.bg)
    }
}

struct SearchView: View {
    @EnvironmentObject var player: Player
    @State private var q = ""

    var results: [Track] {
        let s = q.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if s.isEmpty { return Catalog.tracks }
        return Catalog.tracks.filter {
            $0.title.lowercased().contains(s)
                || Catalog.artistName($0.artistId).lowercased().contains(s)
                || Catalog.albumTitle($0.albumId).lowercased().contains(s)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            TextField("Search songs, artists, albums", text: $q)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(LW.elevated))
                .foregroundStyle(LW.fg)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            ScrollView {
                ForEach(results) { t in
                    TrackRow(id: t.id, queue: results.map(\.id))
                }
            }
        }
        .background(LW.bg)
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DiscoverView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("New this week").font(.headline).foregroundStyle(LW.fg).padding(.horizontal, 16)
                ForEach(Catalog.albums.prefix(6)) { a in
                    NavigationLink(value: "album:\(a.id)") {
                        HStack(spacing: 12) {
                            CoverView(color: a.color, title: a.title, corner: 10).frame(width: 72, height: 72)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(a.title).font(.system(size: 16, weight: .semibold)).foregroundStyle(LW.fg)
                                Text(Catalog.artistName(a.artistId)).foregroundStyle(LW.muted)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(LW.bg)
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GenresView: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Catalog.genres, id: \.self) { g in
                    let ids = Catalog.tracks.filter { $0.genres.contains(g) }.map(\.id)
                    NavigationLink(value: "genre:\(g)") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(g.capitalized).font(.system(size: 18, weight: .semibold)).foregroundStyle(LW.fg)
                            Text("\(ids.count) tracks").font(.caption).foregroundStyle(LW.muted)
                        }
                        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(LW.elevated))
                    }
                }
            }
            .padding(16)
        }
        .background(LW.bg)
        .navigationTitle("Genre DNA")
    }
}

struct GenreTracksView: View {
    let genre: String
    var body: some View {
        let ids = Catalog.tracks.filter { $0.genres.contains(genre) }.map(\.id)
        ScrollView {
            VStack(alignment: .leading) {
                PlayAllButton(ids: ids).padding(16)
                ForEach(ids, id: \.self) { id in TrackRow(id: id, queue: ids) }
            }
        }
        .background(LW.bg)
        .navigationTitle(genre.capitalized)
    }
}

struct FriendsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                NavigationLink(value: "settings") {
                    HStack(spacing: 12) {
                        Circle().fill(LW.chip).frame(width: 56, height: 56)
                            .overlay(Text(String(Catalog.profileName.prefix(1))).font(.title3.weight(.semibold)).foregroundStyle(LW.fg))
                        VStack(alignment: .leading) {
                            Text(Catalog.profileName).font(.headline).foregroundStyle(LW.fg)
                            Text("@\(Catalog.profileHandle)").foregroundStyle(LW.muted)
                        }
                        Spacer()
                        Image(systemName: "gearshape").foregroundStyle(LW.muted)
                    }
                    .padding(.horizontal, 16)
                }
                Text("Listening now").font(.headline).foregroundStyle(LW.fg).padding(.horizontal, 16)
                ForEach(Catalog.friends) { f in
                    NavigationLink(value: "friend:\(f.id)") {
                        HStack(spacing: 12) {
                            CoverView(color: f.color, title: f.name, corner: 22).frame(width: 48, height: 48)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(f.name).foregroundStyle(LW.fg)
                                if let t = Catalog.track(f.nowPlayingId) {
                                    Text("\(t.title) · \(Catalog.artistName(t.artistId))").font(.caption).foregroundStyle(LW.muted).lineLimit(1)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(LW.bg)
        .navigationTitle("Friends")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FriendView: View {
    @EnvironmentObject var player: Player
    let id: String
    var body: some View {
        if let f = Catalog.friends.first(where: { $0.id == id }) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    CoverView(color: f.color, title: f.name, corner: 20).frame(height: 180).padding(.horizontal, 16)
                    Text(f.name).font(.largeTitle.weight(.semibold)).foregroundStyle(LW.fg).padding(.horizontal, 16)
                    Text("@\(f.handle) · \(formatCompact(f.scrobbles)) scrobbles").foregroundStyle(LW.muted).padding(.horizontal, 16)
                    Text(f.bio).padding(.horizontal, 16).foregroundStyle(LW.fg)
                    PlayAllButton(ids: f.topTrackIds).padding(.horizontal, 16)
                    ForEach(f.topTrackIds, id: \.self) { tid in TrackRow(id: tid, queue: f.topTrackIds) }
                }
                .padding(.bottom, 24)
            }
            .background(LW.bg)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var player: Player
    let qualities = ["Max", "Hi-Res", "CD", "Standard"]

    var body: some View {
        List {
            Section("Playback") {
                Picker("Streaming quality", selection: $player.quality) {
                    ForEach(qualities, id: \.self) { Text($0).tag($0) }
                }
                Toggle("Liquid Glass", isOn: $player.liquidGlass)
                Toggle("Shuffle", isOn: $player.shuffle)
            }
            Section("Library") {
                NavigationLink("Downloads (\(player.downloads.count))") { DownloadsView() }
                Text("\(player.scrobbles) scrobbles").foregroundStyle(LW.muted)
            }
            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Bundle", value: "app.lastwave.player")
                Text("Unsigned IPA — sign with Sideloadly, ESign, GBox, or AltStore.")
                    .font(.footnote)
                    .foregroundStyle(LW.muted)
            }
        }
        .scrollContentBackground(.hidden)
        .background(LW.bg)
        .navigationTitle("Settings")
    }
}

struct DownloadsView: View {
    @EnvironmentObject var player: Player
    var body: some View {
        let ids = Array(player.downloads)
        ScrollView {
            if ids.isEmpty {
                Text("Downloaded tracks stay here for offline listening.")
                    .foregroundStyle(LW.muted)
                    .padding(.top, 80)
            } else {
                PlayAllButton(ids: ids).padding(16)
                ForEach(ids, id: \.self) { id in
                    HStack {
                        TrackRow(id: id, queue: ids)
                        Button { player.toggleDownload(id) } label: {
                            Image(systemName: "trash").foregroundStyle(Color(hex: "c45c5c")).frame(width: 44, height: 44)
                        }
                    }
                }
            }
        }
        .background(LW.bg)
        .navigationTitle("Downloads")
    }
}
