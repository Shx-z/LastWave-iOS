import SwiftUI

struct GenerateView: View {
    @EnvironmentObject var player: Player
    @State private var seed: String?
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Create")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(LW.fg)
                        .padding(.top, 12)
                    Text("Build a 12-track taste mix from your listening DNA.")
                        .foregroundStyle(LW.muted)

                    Text("SEED").font(.system(size: 12, weight: .medium)).tracking(1.2).foregroundStyle(LW.muted)
                    FlowChips(items: Catalog.genres, selected: $seed)

                    if player.generating {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(player.generateLabel).foregroundStyle(LW.fg)
                            ProgressView(value: player.generateProgress).tint(LW.accent)
                        }
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: 16).fill(LW.elevated))
                    } else {
                        Button { player.generateMix(seed: seed) } label: {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                Text("Generate mix")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(LW.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(LW.accent))
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Your mixes").font(.headline).foregroundStyle(LW.fg).padding(.top, 8)
                    ForEach(player.playlists.filter(\.generated)) { p in
                        Button { path.append("playlist:\(p.id)") } label: {
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
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(LW.bg)
            .navigationBarHidden(true)
            .navigationDestination(for: String.self) { key in
                if key.hasPrefix("playlist:") { PlaylistView(id: String(key.dropFirst(9))) }
            }
        }
    }
}

struct FlowChips: View {
    let items: [String]
    @Binding var selected: String?
    var body: some View {
        FlexibleWrap {
            ForEach(items, id: \.self) { g in
                Button {
                    selected = selected == g ? nil : g
                } label: {
                    Text(g.capitalized)
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Capsule().fill(selected == g ? LW.accent : LW.elevated))
                        .foregroundStyle(selected == g ? LW.bg : LW.fg)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct FlexibleWrap: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? 320
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > maxW { x = 0; y += rowH + 8; rowH = 0 }
            rowH = max(rowH, sz.height)
            x += sz.width + 8
        }
        return CGSize(width: maxW, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > bounds.maxX { x = bounds.minX; y += rowH + 8; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
            x += sz.width + 8
            rowH = max(rowH, sz.height)
        }
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
    @EnvironmentObject var player: Player
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if let loved = player.liked.first, let t = Catalog.track(loved) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Because you loved \(t.title)").font(.headline).foregroundStyle(LW.fg)
                        let rec = Catalog.tracks.filter { $0.artistId == t.artistId || $0.genres.contains(where: { t.genres.contains($0) }) }.map(\.id)
                        ForEach(rec.prefix(4), id: \.self) { id in TrackRow(id: id, queue: rec) }
                    }
                    .padding(.top, 8)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Live charts").font(.headline).foregroundStyle(LW.fg)
                        Spacer()
                        Text("This week").font(.caption).foregroundStyle(LW.muted)
                    }
                    .padding(.horizontal, 16)
                    ForEach(Array(player.listIds.prefix(8).enumerated()), id: \.element) { i, id in
                        HStack(spacing: 0) {
                            Text("\(i + 1)").font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(LW.muted).frame(width: 28)
                            TrackRow(id: id, queue: player.listIds)
                        }
                    }
                }

                Text("New this week").font(.headline).foregroundStyle(LW.fg).padding(.horizontal, 16)
                ForEach(Catalog.albums.prefix(8)) { a in
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
            .padding(.bottom, 24)
        }
        .background(LW.bg)
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct GenresView: View {
    @EnvironmentObject var player: Player
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Your DNA").font(.headline).foregroundStyle(LW.fg).padding(.horizontal, 16).padding(.top, 8)
                let dna = player.genreDNA
                let maxV = max(dna.map { $0.1 }.max() ?? 1, 1)
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(dna.prefix(6), id: \.0) { g, n in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(g.capitalized).font(.system(size: 13, weight: .medium)).foregroundStyle(LW.fg)
                                Spacer()
                                Button("Start mix") { player.generateMix(seed: g) }
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(LW.tint)
                            }
                            GeometryReader { geo in
                                Capsule().fill(LW.chip)
                                    .overlay(alignment: .leading) {
                                        Capsule().fill(LW.accent)
                                            .frame(width: geo.size.width * CGFloat(n) / CGFloat(maxV))
                                    }
                            }
                            .frame(height: 6)
                        }
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 16).fill(LW.elevated))
                .padding(.horizontal, 16)

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
                            .background(RoundedRectangle(cornerRadius: 16).fill(LW.surface))
                        }
                    }
                }
                .padding(16)
            }
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
                    Button { player.playStation(f.topTrackIds) } label: {
                        Text("Play \(f.name)’s station")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(LW.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(LW.accent))
                            .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
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

    var body: some View {
        List {
            Section("Experimental") {
                Toggle("Liquid Glass", isOn: Binding(
                    get: { player.liquidGlass },
                    set: { player.liquidGlass = $0; player.persist() }
                ))
            }
            Section("Lyrics animation") {
                ForEach(LyricsStyle.allCases, id: \.self) { s in
                    Button {
                        player.lyricsStyle = s
                        player.persist()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(s.title).foregroundStyle(LW.fg)
                                Text(s.hint).font(.caption).foregroundStyle(LW.muted)
                            }
                            Spacer()
                            if player.lyricsStyle == s {
                                Image(systemName: "checkmark").foregroundStyle(LW.tint)
                            }
                        }
                    }
                }
            }
            Section("Equalizer") {
                eqRow("Bass", value: Binding(
                    get: { Double(player.eq.bass) },
                    set: { player.eq.bass = Int($0); player.applyEqVolume(); player.persist() }
                ))
                eqRow("Mid", value: Binding(
                    get: { Double(player.eq.mid) },
                    set: { player.eq.mid = Int($0); player.applyEqVolume(); player.persist() }
                ))
                eqRow("Treble", value: Binding(
                    get: { Double(player.eq.treble) },
                    set: { player.eq.treble = Int($0); player.applyEqVolume(); player.persist() }
                ))
            }
            Section("Streaming quality") {
                ForEach(player.qualities, id: \.id) { q in
                    Button {
                        player.quality = q.id
                        player.persist()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(q.title).foregroundStyle(LW.fg)
                                    Text(q.badge).font(.caption2.weight(.bold)).foregroundStyle(LW.tint)
                                }
                                Text(q.hint).font(.caption).foregroundStyle(LW.muted)
                            }
                            Spacer()
                            if player.quality == q.id {
                                Image(systemName: "checkmark").foregroundStyle(LW.tint)
                            }
                        }
                    }
                }
            }
            Section("Library") {
                NavigationLink("Downloads (\(player.downloads.count))") { DownloadsView() }
                LabeledContent("Scrobbles", value: "\(player.scrobbles)")
                LabeledContent("Loved", value: "\(player.liked.count)")
            }
            Section("About") {
                LabeledContent("Version", value: "1.1.0")
                LabeledContent("Bundle", value: "app.lastwave.player")
                Text("Native iOS player. Catalog is an original session — not YouTube Music / clashflac.")
                    .font(.footnote)
                    .foregroundStyle(LW.muted)
            }
        }
        .scrollContentBackground(.hidden)
        .background(LW.bg)
        .navigationTitle("Settings")
        .tint(LW.accent)
    }

    func eqRow(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value.wrappedValue) > 0 ? "+" : "")\(Int(value.wrappedValue)) dB")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(LW.muted)
            }
            Slider(value: value, in: -8...8, step: 1).tint(LW.accent)
        }
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
