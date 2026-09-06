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

@MainActor
final class Player: ObservableObject {
    @Published var currentId: String?
    @Published var queue: [String] = []
    @Published var playing = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var playerOpen = false
    @Published var lyricsOpen = false
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
    @Published var quality = "Max"

    var current: Track? { currentId.flatMap(Catalog.track) }

    private var av = AVPlayer()
    private var timeObs: Any?
    private var endObs: NSObjectProtocol?
    private var scrobbleArmed = true
    private var ticker: Timer?

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
        setupRemote()
        timeObs = av.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.25, preferredTimescale: 600), queue: .main) { [weak self] t in
            Task { @MainActor in
                self?.currentTime = t.seconds
                if let d = self?.av.currentItem?.duration.seconds, d.isFinite { self?.duration = d }
                self?.tickScrobble()
                self?.publishNowPlaying()
            }
        }
        endObs = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.ended() }
        }
        load()
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
    }

    func toggle() {
        if currentId == nil, let first = Catalog.tracks.first {
            play(first.id)
            return
        }
        if playing { av.pause() } else { av.play() }
        playing = !playing
        publishNowPlaying()
    }

    func next() {
        guard let id = currentId, let i = queue.firstIndex(of: id) else { return }
        if repeatMode == .one { loadTrack(id); av.play(); playing = true; return }
        let n = i + 1
        if n < queue.count { loadTrack(queue[n]); av.play(); playing = true }
        else if repeatMode == .all, let first = queue.first { loadTrack(first); av.play(); playing = true }
        else { playing = false; av.pause() }
    }

    func prev() {
        if currentTime > 3 { seek(0); return }
        guard let id = currentId, let i = queue.firstIndex(of: id), i > 0 else { seek(0); return }
        loadTrack(queue[i - 1])
        av.play()
        playing = true
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
        if downloads.contains(id) { downloads.remove(id) } else { downloads.insert(id) }
        persist()
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

    func generateMix() {
        generating = true
        generateProgress = 0
        let labels = ["Reading taste…", "Clustering colors…", "Sequencing night…", "Sealing mix…"]
        Task {
            for (i, l) in labels.enumerated() {
                generateLabel = l
                generateProgress = Double(i + 1) / Double(labels.count)
                try? await Task.sleep(nanoseconds: 450_000_000)
            }
            var ids = Array(liked)
            if ids.count < 6 { ids += recent }
            ids += Catalog.tracks.map(\.id)
            var seen = Set<String>()
            let mix = ids.filter { seen.insert($0).inserted }.prefix(7).map { $0 }
            let id = UUID().uuidString
            playlists.insert(Playlist(id: id, title: "Taste Mix", subtitle: "Generated for you", color: "3d5c68", trackIds: Array(mix), generated: true, createdAt: "Just now"), at: 0)
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

    private func loadTrack(_ id: String) {
        currentId = id
        currentTime = 0
        scrobbleArmed = true
        lyricsOpen = false
        guard let track = Catalog.track(id) else { return }
        duration = track.duration
        if let url = Bundle.main.url(forResource: track.audioFile, withExtension: "mp3") {
            av.replaceCurrentItem(with: AVPlayerItem(url: url))
        } else if let url = URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-\(track.audioFile.replacingOccurrences(of: "track-", with: "")).mp3") {
            av.replaceCurrentItem(with: AVPlayerItem(url: url))
        }
        publishNowPlaying()
        persist()
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
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: t.title,
            MPMediaItemPropertyArtist: Catalog.artistName(t.artistId),
            MPMediaItemPropertyAlbumTitle: Catalog.albumTitle(t.albumId),
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: playing ? 1.0 : 0.0,
        ]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        _ = info
    }

    private func persist() {
        let d = UserDefaults.standard
        d.set(Array(liked), forKey: "liked")
        d.set(Array(downloads), forKey: "downloads")
        d.set(recent, forKey: "recent")
        d.set(scrobbles, forKey: "scrobbles")
        d.set(listenedSeconds, forKey: "listened")
        d.set(shuffle, forKey: "shuffle")
        d.set(repeatMode.rawValue, forKey: "repeat")
        d.set(liquidGlass, forKey: "glass")
        if let data = try? JSONEncoder().encode(playlists) { d.set(data, forKey: "playlists") }
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
        if let data = d.data(forKey: "playlists"), let p = try? JSONDecoder().decode([Playlist].self, from: data) { playlists = p }
    }
}
