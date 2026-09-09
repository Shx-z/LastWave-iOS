import AVFoundation
import Combine
import MediaPlayer
import SwiftUI
import UIKit

enum RepeatMode: String, Codable, CaseIterable {
    case off, all, one
}

enum ListFilter: String, CaseIterable {
    case recent, loved, top
}

enum LyricsStyle: String, Codable, CaseIterable {
    case appleFluid = "apple-fluid"
    case karaokePulse = "karaoke-pulse"
    case kineticSlide = "kinetic-slide"
    case wordSpotlight = "word-spotlight"
    case rtlCascade = "rtl-cascade"
    case fullscreenFocus = "fullscreen-focus"
    case driftFade = "drift-fade"
    case pulseWave = "pulse-wave"
    var title: String {
        switch self {
        case .appleFluid: return "Apple Fluid"
        case .karaokePulse: return "Karaoke Pulse"
        case .kineticSlide: return "Kinetic Slide"
        case .wordSpotlight: return "Word Spotlight"
        case .rtlCascade: return "RTL Cascade"
        case .fullscreenFocus: return "Fullscreen Focus"
        case .driftFade: return "Drift Fade"
        case .pulseWave: return "Pulse Wave"
        }
    }
    var hint: String {
        switch self {
        case .appleFluid: return "Smooth spring scaling with focal tracking"
        case .karaokePulse: return "Active line lifts in silver against the rest"
        case .kineticSlide: return "Lines drift in as the playhead crosses them"
        case .wordSpotlight: return "Word-by-word karaoke with timed highlights"
        case .rtlCascade: return "Arabic and Hebrew lines flow right-to-left"
        case .fullscreenFocus: return "One line at a time, cinematic"
        case .driftFade: return "Past lines dissolve, future stays quiet"
        case .pulseWave: return "Beat-synced scale on the singing line"
        }
    }
}

struct EqState: Codable, Equatable {
    var bass: Int = 0
    var mid: Int = 0
    var treble: Int = 0
}

@MainActor
final class Player: ObservableObject {
    @Published var currentId: String?
    @Published var queue: [String] = []
    @Published var playing = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var playerOpen = false
    @Published var lyricsOpen = false
    @Published var queueOpen = false
    @Published var shuffle = false
    @Published var repeatMode: RepeatMode = .off
    @Published var liked: Set<String> = ["harbor-lights", "pulse", "sun-within"]
    @Published var downloads: Set<String> = ["harbor-lights", "late-signal"]
    @Published var recent: [String] = ["harbor-lights", "pulse", "sun-within", "after-rain", "patchbay", "receding-names", "ember-line", "ribbon-steel"]
    @Published var playlists: [Playlist] = Catalog.seedPlaylists
    @Published var scrobbles = 19588
    @Published var listenedSeconds = 18640
    @Published var listFilter: ListFilter = .recent
    @Published var generating = false
    @Published var generateProgress: Double = 0
    @Published var generateLabel = ""
    @Published var liquidGlass = true
    @Published var quality = "max"
    @Published var lyricsStyle: LyricsStyle = .wordSpotlight
    @Published var eq = EqState()
    @Published var sleepMinutes: Int? = nil
    @Published var trending: [Track] = []
    @Published var downloading: Set<String> = []
    @Published var streamReady = false
    @Published var releases: [Track] = []
    @Published var releasesDone = false
    @Published var lyricsFull = false
    @Published var importBusy = false

    var current: Track? { currentId.flatMap(Catalog.track) }

    let qualities: [(id: String, title: String, badge: String, hint: String)] = [
        ("max", "Max Quality", "24-BIT / 192k", "Up to 24-bit / 192 kHz · Lossless Studio FLAC"),
        ("hires", "Hi-Res Audio", "24-BIT / 96k", "24-bit / 96 kHz · Lossless Studio FLAC"),
        ("cd", "CD Lossless", "16-BIT / 44.1k", "16-bit / 44.1 kHz · Lossless CD FLAC"),
        ("standard", "Standard Quality", "320 kbps", "320 kbps · MP3 (Data Saver)"),
    ]

    var qualityBadge: String {
        qualities.first { $0.id == quality }?.badge ?? "24-BIT / 96k"
    }

    private var av = AVPlayer()
    private var timeObs: Any?
    private var endObs: NSObjectProtocol?
    private var scrobbleArmed = true
    private var sleepDeadline: Date?
    private let haptic = UIImpactFeedbackGenerator(style: .soft)

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
        setupRemote()
        timeObs = av.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.2, preferredTimescale: 600), queue: .main) { [weak self] t in
            Task { @MainActor in
                guard let self else { return }
                self.currentTime = t.seconds
                if let d = self.av.currentItem?.duration.seconds, d.isFinite, d > 0 { self.duration = d }
                self.tickScrobble()
                self.tickSleep()
                self.publishNowPlaying()
            }
        }
        endObs = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.ended() }
        }
        load()
        haptic.prepare()
        Task { await loadTrending() }
    }

    func play(_ id: String, queue q: [String]? = nil) {
        let base = q ?? Catalog.tracks.map(\.id)
        var nextQ = base
        if shuffle {
            nextQ = [id] + base.filter { $0 != id }.shuffled()
        } else if let i = base.firstIndex(of: id) {
            nextQ = Array(base[i...]) + Array(base[..<i])
        }
        queue = nextQ
        loadTrack(id)
        av.play()
        playing = true
        bumpRecent(id)
        haptic.impactOccurred()
    }

    func toggle() {
        if currentId == nil, let first = Catalog.tracks.first {
            play(first.id)
            return
        }
        if playing { av.pause() } else { av.play() }
        playing = !playing
        haptic.impactOccurred()
        publishNowPlaying()
    }

    func next() {
        haptic.impactOccurred()
        guard let id = currentId, let i = queue.firstIndex(of: id) else { return }
        if repeatMode == .one { loadTrack(id); av.play(); playing = true; return }
        let n = i + 1
        if n < queue.count { loadTrack(queue[n]); av.play(); playing = true; bumpRecent(queue[n]) }
        else if repeatMode == .all, let first = queue.first { loadTrack(first); av.play(); playing = true }
        else { playing = false; av.pause() }
    }

    func prev() {
        haptic.impactOccurred()
        if currentTime > 3 { seek(0); return }
        guard let id = currentId, let i = queue.firstIndex(of: id), i > 0 else { seek(0); return }
        loadTrack(queue[i - 1])
        av.play()
        playing = true
        bumpRecent(queue[i - 1])
    }

    func seek(_ t: Double) {
        av.seek(to: CMTime(seconds: max(0, t), preferredTimescale: 600))
        currentTime = t
    }

    func cycleRepeat() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
        persist()
    }

    func toggleLike(_ id: String) {
        if liked.contains(id) { liked.remove(id) } else { liked.insert(id) }
        persist()
    }

    func toggleDownload(_ id: String) {
        if DownloadsFS.exists(id) {
            DownloadsFS.remove(id)
            downloads.remove(id)
            persist()
            return
        }
        guard let t = Catalog.track(id) else { return }
        if !t.remote {
            if downloads.contains(id) { downloads.remove(id) } else { downloads.insert(id) }
            persist()
            return
        }
        Task { await downloadRemote(id) }
    }

    func isOffline(_ id: String) -> Bool {
        DownloadsFS.exists(id) || (downloads.contains(id) && !(Catalog.track(id)?.remote ?? false))
    }

    func loadTrending() async {
        let list = await StreamAPI.trending()
        Catalog.ingest(list)
        trending = list
        streamReady = true
        persist()
    }

    func loadMoreReleases() async {
        if releasesDone { return }
        let list = await StreamAPI.trending(limit: 16, offset: releases.count, time: "month")
        Catalog.ingest(list)
        if list.isEmpty { releasesDone = true; return }
        releases += list
        persist()
    }

    func importPlaylist(raw: String) async -> String? {
        importBusy = true
        defer { importBusy = false }
        let lines = raw.split(whereSeparator: \.isNewline).map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") && !$0.lowercased().hasPrefix("http") }
        var ids: [String] = []
        for line in lines.prefix(20) {
            let title = line.split { $0 == "," || $0 == "-" || $0 == "–" }.map(String.init).last?.trimmingCharacters(in: .whitespaces) ?? line
            let hits = await StreamAPI.search(title, limit: 3)
            Catalog.ingest(hits)
            if let first = hits.first { ids.append(first.id) }
        }
        guard !ids.isEmpty else { return nil }
        let id = UUID().uuidString
        playlists.insert(Playlist(id: id, title: "Imported Playlist", subtitle: "\(ids.count) tracks · imported", color: "8a6a82", trackIds: ids, generated: false, createdAt: "Just now"), at: 0)
        persist()
        return id
    }

    func searchCloud(_ q: String) async -> [Track] {
        let hits = await StreamAPI.search(q)
        Catalog.ingest(hits)
        persist()
        return hits
    }

    func fetchLyricsIfNeeded(_ id: String) async {
        guard var t = Catalog.track(id), t.lyrics.isEmpty else { return }
        let lines = await StreamAPI.lyrics(title: t.title, artist: t.displayArtist)
        guard !lines.isEmpty else { return }
        t.lyrics = lines
        Catalog.cloud[id] = t
        if currentId == id { objectWillChange.send() }
    }

    private func downloadRemote(_ id: String) async {
        guard let t = Catalog.track(id),
              let s = t.streamURL,
              let url = URL(string: s) else { return }
        downloading.insert(id)
        defer { downloading.remove(id) }
        do {
            let (tmp, resp) = try await URLSession.shared.download(from: url)
            guard let http = resp as? HTTPURLResponse, (200..<400).contains(http.statusCode) else { return }
            let dest = DownloadsFS.file(for: id)
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.moveItem(at: tmp, to: dest)
            downloads.insert(id)
            persist()
        } catch {
            // keep UI quiet — retry from the row
        }
    }

    func createPlaylist(title: String, tracks ids: [String] = []) -> String {
        let id = UUID().uuidString
        playlists.insert(Playlist(id: id, title: title, subtitle: "\(ids.count) tracks", color: "6a8b96", trackIds: ids, generated: false, createdAt: "Just now"), at: 0)
        persist()
        return id
    }

    func addToPlaylist(_ pid: String, track id: String) {
        guard let i = playlists.firstIndex(where: { $0.id == pid }) else { return }
        if !playlists[i].trackIds.contains(id) { playlists[i].trackIds.append(id) }
        persist()
    }

    func playStation(_ ids: [String]) {
        guard let first = ids.first else { return }
        play(first, queue: ids)
        playerOpen = true
    }

    func setSleep(_ minutes: Int?) {
        sleepMinutes = minutes
        if let m = minutes, m > 0 {
            sleepDeadline = Date().addingTimeInterval(TimeInterval(m * 60))
        } else {
            sleepDeadline = nil
        }
    }

    func generateMix(seed: String? = nil) {
        generating = true
        generateProgress = 0
        let labels = ["Reading taste…", "Clustering colors…", "Matching Genre DNA…", "Sequencing night…", "Sealing mix…"]
        Task {
            for (i, l) in labels.enumerated() {
                generateLabel = l
                generateProgress = Double(i + 1) / Double(labels.count)
                try? await Task.sleep(nanoseconds: 380_000_000)
            }
            var ids: [String] = []
            if let seed {
                ids += Catalog.tracks.filter { $0.genres.contains(seed) }.map(\.id)
            }
            ids += Array(liked)
            ids += recent
            ids += trending.map(\.id)
            ids += Catalog.tracks.map(\.id)
            var seen = Set<String>()
            let mix = ids.filter { seen.insert($0).inserted }.prefix(12).map { $0 }
            let id = UUID().uuidString
            let title = seed.map { "\($0.capitalized) Mix" } ?? "Taste Mix"
            playlists.insert(Playlist(id: id, title: title, subtitle: "\(mix.count) tracks · generated", color: "3d5c68", trackIds: Array(mix), generated: true, createdAt: "Just now"), at: 0)
            generating = false
            persist()
        }
    }

    var listIds: [String] {
        switch listFilter {
        case .loved: return Array(liked)
        case .top:
            var c: [String: Int] = [:]
            recent.forEach { c[$0, default: 0] += 2 }
            liked.forEach { c[$0, default: 0] += 3 }
            return c.sorted { $0.value > $1.value }.map(\.key)
        case .recent:
            return recent.isEmpty ? Catalog.tracks.map(\.id) : recent
        }
    }

    var genreDNA: [(String, Int)] {
        var c: [String: Int] = [:]
        for id in liked { Catalog.track(id)?.genres.forEach { c[$0, default: 0] += 3 } }
        for id in recent { Catalog.track(id)?.genres.forEach { c[$0, default: 0] += 1 } }
        if c.isEmpty {
            return Catalog.genres.prefix(6).map { ($0, 4) }
        }
        return c.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }

    private func loadTrack(_ id: String) {
        currentId = id
        currentTime = 0
        scrobbleArmed = true
        guard let track = Catalog.track(id) else { return }
        duration = track.duration
        if DownloadsFS.exists(id) {
            av.replaceCurrentItem(with: AVPlayerItem(url: DownloadsFS.file(for: id)))
        } else if !track.audioFile.isEmpty, let url = Bundle.main.url(forResource: track.audioFile, withExtension: "mp3") {
            av.replaceCurrentItem(with: AVPlayerItem(url: url))
        } else if let s = track.streamURL, let url = URL(string: s) {
            av.replaceCurrentItem(with: AVPlayerItem(url: url))
        }
        applyEqVolume()
        publishNowPlaying()
        persist()
        if track.lyrics.isEmpty {
            Task { await fetchLyricsIfNeeded(id) }
        }
    }

    func applyEqVolume() {
        av.volume = 1
    }

    private func ended() {
        listenedSeconds += Int(duration)
        next()
        persist()
    }

    private func tickScrobble() {
        guard scrobbleArmed, duration > 0, currentTime > min(duration * 0.5, 40) else { return }
        scrobbleArmed = false
        scrobbles += 1
        persist()
    }

    private func tickSleep() {
        guard let d = sleepDeadline, Date() >= d else { return }
        sleepDeadline = nil
        sleepMinutes = nil
        av.pause()
        playing = false
        publishNowPlaying()
    }

    private func bumpRecent(_ id: String) {
        recent.removeAll { $0 == id }
        recent.insert(id, at: 0)
        if recent.count > 24 { recent = Array(recent.prefix(24)) }
    }

    private func setupRemote() {
        let r = MPRemoteCommandCenter.shared()
        r.playCommand.addTarget { [weak self] _ in Task { @MainActor in self?.av.play(); self?.playing = true }; return .success }
        r.pauseCommand.addTarget { [weak self] _ in Task { @MainActor in self?.av.pause(); self?.playing = false }; return .success }
        r.togglePlayPauseCommand.addTarget { [weak self] _ in Task { @MainActor in self?.toggle() }; return .success }
        r.nextTrackCommand.addTarget { [weak self] _ in Task { @MainActor in self?.next() }; return .success }
        r.previousTrackCommand.addTarget { [weak self] _ in Task { @MainActor in self?.prev() }; return .success }
        r.changePlaybackPositionCommand.addTarget { [weak self] e in
            if let e = e as? MPChangePlaybackPositionCommandEvent {
                Task { @MainActor in self?.seek(e.positionTime) }
            }
            return .success
        }
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    private func publishNowPlaying() {
        guard let t = current else { return }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: t.title,
            MPMediaItemPropertyArtist: t.displayArtist,
            MPMediaItemPropertyAlbumTitle: Catalog.albumTitle(t.albumId),
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: playing ? 1.0 : 0.0,
        ]
    }

    func persist() {
        let d = UserDefaults.standard
        d.set(Array(liked), forKey: "liked")
        d.set(Array(downloads), forKey: "downloads")
        d.set(recent, forKey: "recent")
        d.set(scrobbles, forKey: "scrobbles")
        d.set(listenedSeconds, forKey: "listened")
        d.set(shuffle, forKey: "shuffle")
        d.set(repeatMode.rawValue, forKey: "repeat")
        d.set(liquidGlass, forKey: "glass")
        d.set(quality, forKey: "quality")
        d.set(lyricsStyle.rawValue, forKey: "lyricsStyle")
        if let data = try? JSONEncoder().encode(playlists) { d.set(data, forKey: "playlists") }
        if let data = try? JSONEncoder().encode(eq) { d.set(data, forKey: "eq") }
        if let data = try? JSONEncoder().encode(Array(Catalog.cloud.values)) { d.set(data, forKey: "cloud") }
    }

    private func load() {
        let d = UserDefaults.standard
        if let v = d.array(forKey: "liked") as? [String] { liked = Set(v) }
        if let v = d.array(forKey: "downloads") as? [String] { downloads = Set(v) }
        if let v = d.array(forKey: "recent") as? [String] { recent = v }
        if d.object(forKey: "scrobbles") != nil { scrobbles = d.integer(forKey: "scrobbles") }
        if d.object(forKey: "listened") != nil { listenedSeconds = d.integer(forKey: "listened") }
        shuffle = d.bool(forKey: "shuffle")
        if let r = d.string(forKey: "repeat"), let m = RepeatMode(rawValue: r) { repeatMode = m }
        if d.object(forKey: "glass") != nil { liquidGlass = d.bool(forKey: "glass") }
        if let q = d.string(forKey: "quality") { quality = q }
        if let s = d.string(forKey: "lyricsStyle"), let st = LyricsStyle(rawValue: s) { lyricsStyle = st }
        if let data = d.data(forKey: "playlists"), let p = try? JSONDecoder().decode([Playlist].self, from: data) { playlists = p }
        if let data = d.data(forKey: "eq"), let e = try? JSONDecoder().decode(EqState.self, from: data) { eq = e }
        if let data = d.data(forKey: "cloud"), let extra = try? JSONDecoder().decode([Track].self, from: data) {
            Catalog.ingest(extra)
        }
    }
}
