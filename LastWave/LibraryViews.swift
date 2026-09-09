import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var player: Player
    @State private var path = NavigationPath()
    @State private var newName = ""
    @State private var importText = ""

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Playlists")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundStyle(LW.fg)
                            Text("\(player.playlists.count) Playlists · \(player.playlists.reduce(0) { $0 + $1.trackIds.count }) Tracks")
                                .font(.system(size: 13))
                                .foregroundStyle(LW.muted)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    HStack(spacing: 8) {
                        TextField("New playlist", text: $newName)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(LW.elevated))
                            .foregroundStyle(LW.fg)
                        Button("Create") {
                            let t = newName.trimmingCharacters(in: .whitespaces)
                            if !t.isEmpty {
                                let id = player.createPlaylist(title: t)
                                newName = ""
                                path.append("playlist:\(id)")
                            }
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(LW.bg)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(LW.accent))
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 8) {
                        TextEditor(text: $importText)
                            .frame(height: 72)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 12).fill(LW.elevated))
                            .foregroundStyle(LW.fg)
                            .scrollContentBackground(.hidden)
                        Button(player.importBusy ? "Matching tracks…" : "Import playlist") {
                            Task {
                                if let id = await player.importPlaylist(raw: importText) {
                                    importText = ""
                                    path.append("playlist:\(id)")
                                }
                            }
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(LW.fg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(LW.chip))
                        .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || player.importBusy)
                    }
                    .padding(.horizontal, 16)

                    Button { path.append("downloads") } label: {
                        HStack {
                            Image(systemName: "arrow.down.circle").foregroundStyle(LW.tint)
                            Text("Downloads").foregroundStyle(LW.fg)
                            Spacer()
                            Text("\(player.downloads.count) songs").foregroundStyle(LW.muted)
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 16).fill(LW.chip))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)

                    VStack(spacing: 6) {
                        ForEach(player.playlists) { p in
                            HStack(spacing: 12) {
                                Button { path.append("playlist:\(p.id)") } label: {
                                    HStack(spacing: 12) {
                                        CoverView(color: p.color, title: p.title, corner: 12)
                                            .frame(width: 56, height: 56)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(p.title).font(.system(size: 16, weight: .medium)).foregroundStyle(LW.fg).lineLimit(1)
                                            Text("\(p.trackIds.count) tracks · \(p.createdAt)").font(.system(size: 12)).foregroundStyle(LW.muted)
                                        }
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                                if let first = p.trackIds.first {
                                    Button { player.play(first, queue: p.trackIds) } label: {
                                        Image(systemName: "play.fill").foregroundStyle(LW.fg)
                                            .frame(width: 44, height: 44)
                                            .background(Circle().fill(LW.chip))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .background(LW.bg)
            .navigationBarHidden(true)
            .navigationDestination(for: String.self) { key in
                if key.hasPrefix("playlist:") { PlaylistView(id: String(key.dropFirst(9))) }
                else if key == "downloads" { DownloadsView() }
            }
        }
    }
}

struct PlaylistView: View {
    @EnvironmentObject var player: Player
    let id: String

    var body: some View {
        let p = player.playlists.first { $0.id == id }
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let p {
                    CoverView(color: p.color, title: p.title, corner: 20)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .padding(.horizontal, 48)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(p.title).font(.system(size: 28, weight: .semibold)).foregroundStyle(LW.fg)
                        Text(p.subtitle).foregroundStyle(LW.muted)
                        PlayAllButton(ids: p.trackIds).padding(.top, 8)
                    }
                    .padding(.horizontal, 16)
                    ForEach(p.trackIds, id: \.self) { tid in
                        TrackRow(id: tid, queue: p.trackIds)
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .background(LW.bg)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AlbumView: View {
    @EnvironmentObject var player: Player
    let id: String
    var body: some View {
        if let a = Catalog.album(id) {
            let ids = Catalog.tracks(album: id).map(\.id)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    CoverView(color: a.color, title: a.title, corner: 20)
                        .aspectRatio(1, contentMode: .fit)
                        .padding(.horizontal, 48)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(a.title).font(.system(size: 28, weight: .semibold)).foregroundStyle(LW.fg)
                        NavigationLink(value: "artist:\(a.artistId)") {
                            Text(Catalog.artistName(a.artistId)).foregroundStyle(LW.tint)
                        }
                        Text(a.year).foregroundStyle(LW.muted)
                        PlayAllButton(ids: ids).padding(.top, 8)
                    }
                    .padding(.horizontal, 16)
                    ForEach(ids, id: \.self) { tid in TrackRow(id: tid, queue: ids) }
                }
                .padding(.bottom, 24)
            }
            .background(LW.bg)
        }
    }
}

struct ArtistView: View {
    let id: String
    var body: some View {
        if let a = Catalog.artist(id) {
            let ids = Catalog.tracks(artist: id).map(\.id)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    CoverView(color: a.color, title: a.name, corner: 20)
                        .frame(height: 220)
                        .padding(.horizontal, 16)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(a.name).font(.system(size: 28, weight: .semibold)).foregroundStyle(LW.fg)
                        Text("\(a.listeners) listeners").foregroundStyle(LW.muted)
                        Text(a.bio).font(.system(size: 15)).foregroundStyle(LW.fg.opacity(0.85)).padding(.top, 4)
                        PlayAllButton(ids: ids).padding(.top, 8)
                    }
                    .padding(.horizontal, 16)
                    ForEach(Catalog.albums(artist: id)) { al in
                        NavigationLink(value: "album:\(al.id)") {
                            HStack {
                                CoverView(color: al.color, title: al.title, corner: 8).frame(width: 56, height: 56)
                                VStack(alignment: .leading) {
                                    Text(al.title).foregroundStyle(LW.fg)
                                    Text(al.year).font(.caption).foregroundStyle(LW.muted)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    ForEach(ids, id: \.self) { tid in TrackRow(id: tid, queue: ids) }
                }
                .padding(.bottom, 24)
            }
            .background(LW.bg)
        }
    }
}
