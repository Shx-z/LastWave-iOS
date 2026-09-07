import Foundation

enum StreamAPI {
    static let app = "LastWave"
    static let root = "https://api.audius.co/v1"

    static func streamURL(audiusId: String) -> URL? {
        URL(string: "\(root)/tracks/\(audiusId)/stream?app_name=\(app)")
    }

    static func trending(limit: Int = 24) async -> [Track] {
        await fetch("\(root)/tracks/trending?app_name=\(app)&limit=\(limit)")
    }

    static func search(_ q: String, limit: Int = 24) async -> [Track] {
        let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q
        return await fetch("\(root)/tracks/search?query=\(encoded)&app_name=\(app)&limit=\(limit)")
    }

    static func lyrics(title: String, artist: String) async -> [LyricLine] {
        let t = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
        let a = artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? artist
        guard let url = URL(string: "https://lrclib.net/api/search?track_name=\(t)&artist_name=\(a)") else { return [] }
        var req = URLRequest(url: url)
        req.setValue("LastWave/1.2 (iOS)", forHTTPHeaderField: "User-Agent")
        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
        let synced = (arr.first?["syncedLyrics"] as? String) ?? ""
        if synced.isEmpty {
            let plain = (arr.first?["plainLyrics"] as? String) ?? ""
            return plain.split(separator: "\n").enumerated().map { i, line in
                LyricLine(t: Double(i) * 4, text: String(line))
            }
        }
        return parseLRC(synced)
    }

    private static func fetch(_ url: String) async -> [Track] {
        guard let u = URL(string: url),
              let (data, _) = try? await URLSession.shared.data(from: u),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let arr = obj["data"] as? [[String: Any]] else { return [] }
        let tracks = arr.compactMap(mapTrack)
        return tracks
    }

    private static func mapTrack(_ d: [String: Any]) -> Track? {
        guard let id = d["id"] as? String, let title = d["title"] as? String else { return nil }
        if d["is_streamable"] as? Bool == false { return nil }
        let user = d["user"] as? [String: Any] ?? [:]
        let artist = (user["name"] as? String) ?? "Unknown"
        let artistId = (user["id"] as? String) ?? "au-\(id)"
        let art = d["artwork"] as? [String: Any]
        let artURL = (art?["480x480"] as? String) ?? (art?["150x150"] as? String)
        let duration = Double(d["duration"] as? Int ?? 0)
        let genre = ((d["genre"] as? String) ?? "electronic").lowercased()
        let lid = "au:\(id)"
        return Track(
            id: lid,
            title: title,
            artistId: artistId,
            albumId: "audius",
            audioFile: "",
            duration: duration,
            genres: [genre],
            quality: "STREAM",
            color: Catalog.color(for: lid),
            lyrics: [],
            streamURL: streamURL(audiusId: id)?.absoluteString,
            artworkURL: artURL,
            artistLabel: artist,
            remote: true
        )
    }

    private static func parseLRC(_ raw: String) -> [LyricLine] {
        var out: [LyricLine] = []
        for line in raw.split(separator: "\n") {
            let s = String(line)
            guard s.hasPrefix("["), let close = s.firstIndex(of: "]") else { continue }
            let tag = String(s[s.index(after: s.startIndex)..<close])
            let parts = tag.split(separator: ":")
            guard parts.count >= 2, let m = Double(parts[0]), let sec = Double(parts[1]) else { continue }
            let text = String(s[s.index(after: close)...]).trimmingCharacters(in: .whitespaces)
            if !text.isEmpty { out.append(LyricLine(t: m * 60 + sec, text: text)) }
        }
        return out
    }
}

enum DownloadsFS {
    static var dir: URL {
        let d = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("LastWave", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }

    static func file(for id: String) -> URL {
        let safe = id.replacingOccurrences(of: ":", with: "_")
        return dir.appendingPathComponent("\(safe).mp3")
    }

    static func exists(_ id: String) -> Bool {
        FileManager.default.fileExists(atPath: file(for: id).path)
    }

    static func remove(_ id: String) {
        try? FileManager.default.removeItem(at: file(for: id))
    }
}
