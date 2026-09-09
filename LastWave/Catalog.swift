import Foundation

struct LyricLine: Hashable, Codable {
    let t: Double
    let text: String
}

struct Artist: Identifiable, Hashable {
    let id: String
    let name: String
    let bio: String
    let listeners: String
    let genres: [String]
    let color: String
}

struct Album: Identifiable, Hashable {
    let id: String
    let title: String
    let artistId: String
    let year: String
    let color: String
}

struct Track: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let artistId: String
    let albumId: String
    let audioFile: String
    let duration: Double
    let genres: [String]
    let quality: String
    let color: String
    var lyrics: [LyricLine]
    var streamURL: String? = nil
    var artworkURL: String? = nil
    var artistLabel: String? = nil
    var remote: Bool = false

    var displayArtist: String { artistLabel ?? Catalog.artistName(artistId) }
}

struct Playlist: Identifiable, Hashable, Codable {
    var id: String
    var title: String
    var subtitle: String
    var color: String
    var trackIds: [String]
    var generated: Bool
    var createdAt: String
}

struct Friend: Identifiable, Hashable {
    let id: String
    let name: String
    let handle: String
    let color: String
    let nowPlayingId: String
    let scrobbles: Int
    let topTrackIds: [String]
    let recentIds: [String]
    let topArtistIds: [String]
    let bio: String
}

enum Catalog {
    static func L(_ lines: [String], gap: Double = 7.2) -> [LyricLine] {
        lines.enumerated().map { LyricLine(t: 1.6 + Double($0.offset) * gap, text: $0.element) }
    }

    static let artists: [Artist] = [
        .init(id: "mira", name: "Mira Vale", bio: "Mira Vale writes slow-blooming ambient from a converted boathouse on the North Sea.", listeners: "84.2K", genres: ["ambient", "chillout", "coastal"], color: "6a8b96"),
        .init(id: "lumen", name: "Lumen Fold", bio: "A two-person studio in Lisbon folding broken beats into weather systems.", listeners: "121K", genres: ["electronic", "idm", "rain"], color: "4a7a88"),
        .init(id: "nara", name: "Nara Sol", bio: "Composer and tanpura student based in Cologne.", listeners: "70.8K", genres: ["new age", "world", "devotional"], color: "c4a46a"),
        .init(id: "sable", name: "Sable Radio", bio: "Night-shift broadcasts from an unnamed station.", listeners: "96.4K", genres: ["noir", "downtempo", "city"], color: "3d5c68"),
        .init(id: "copper", name: "Copper Room", bio: "Hardware-only sessions from a basement in Osaka.", listeners: "54.1K", genres: ["analog", "kraut", "synth"], color: "b07a4a"),
        .init(id: "tide", name: "Tide Letters", bio: "Sparse guitar and whispered close-mics, recorded at actual low tide.", listeners: "41.7K", genres: ["folk", "ambient", "acoustic"], color: "6a7d70"),
        .init(id: "ash", name: "Ash Canyon", bio: "A desert four-piece tracking to tape under a tin roof.", listeners: "63.9K", genres: ["desert", "slowcore", "rock"], color: "8a5a42"),
        .init(id: "optic", name: "Optic North", bio: "Sculptural techno from Malmö.", listeners: "88.0K", genres: ["electronic", "minimal", "steel"], color: "8a8680"),
    ]

    static let albums: [Album] = [
        .init(id: "glass-harbor", title: "Glass Harbor", artistId: "mira", year: "2026", color: "6a8b96"),
        .init(id: "hazy-monsoon", title: "Hazy Monsoon", artistId: "lumen", year: "2026", color: "4a7a88"),
        .init(id: "sun-within", title: "Sun Within", artistId: "nara", year: "2025", color: "c4a46a"),
        .init(id: "velvet-radio", title: "Velvet Radio", artistId: "sable", year: "2025", color: "8a6a62"),
        .init(id: "night-shift", title: "Night Shift", artistId: "sable", year: "2026", color: "3d5c68"),
        .init(id: "copper-pulse", title: "Copper Pulse", artistId: "copper", year: "2026", color: "b07a4a"),
        .init(id: "low-tide", title: "Low Tide Letters", artistId: "tide", year: "2025", color: "6a7d70"),
        .init(id: "crimson-canyon", title: "Crimson Canyon", artistId: "ash", year: "2026", color: "8a5a42"),
        .init(id: "kinetic-dust", title: "Kinetic Dust", artistId: "optic", year: "2026", color: "8a8680"),
        .init(id: "afterimage", title: "Afterimage", artistId: "optic", year: "2025", color: "9aa4b0"),
    ]

    static let tracks: [Track] = [
        T("harbor-lights", "Harbor Lights", "mira", "glass-harbor", "track-1", "6a8b96", ["ambient", "chillout"], "FLAC 24/96", [
            "The pier keeps the hour we left it", "Salt on the railing, a slow green lamp", "Boats argue softly with the dark",
            "I count the windows still awake", "Fog writes your name and takes it back", "A horn from somewhere I can't see",
            "We said we'd wait for clearer weather", "The water does not keep that kind of promise", "Harbor lights fold into the tide",
            "I hold the last warm coin of summer", "Walk the boards until they quiet", "Come home by the sound, not the map",
        ]),
        T("blue-hour", "Blue Hour", "mira", "glass-harbor", "track-2", "6a8b96", ["ambient", "coastal"], "FLAC 24/192", [
            "Between the day and the invented night", "Everything is the color of waiting", "Gulls stitch a line across the west",
            "Your coat still hangs like a decision", "The kettle knows more than I do", "Blue hour is a door left open",
            "I almost call, I almost don't", "Glass harbor holding a second sky", "If I stay still the light will stay",
            "It never does, it never does", "Only the tide keeps appointments", "And even then, only twice",
        ]),
        T("pulse", "Pulse", "lumen", "hazy-monsoon", "track-3", "4a7a88", ["electronic", "idm"], "FLAC 24/96", [
            "A click becomes a weather system", "Rain learns the shape of the kick", "City grid flickering in 7/8",
            "We are the delay, not the note", "Monsoon pressure on the glass", "Fold the beat until it breathes",
            "Streetlights counting in pairs", "I lose the one and find a better one", "Static is also a kind of choir",
            "Keep the pulse under the tongue", "When it breaks, let it break clean", "Then start the rain again",
        ]),
        T("monsoon-static", "Monsoon Static", "lumen", "hazy-monsoon", "track-4", "4a7a88", ["electronic", "rain"], "FLAC 24/96", [
            "The radio eats the storm and smiles", "Every channel is water tonight", "I tune for a voice and get weather",
            "Haze on the marble of the sky", "Cars drawing silver down the hill", "We talk in the gaps between drops",
            "A snare like a shutter, then none", "Hold this frequency, don't drift", "The city is a drum left in the rain",
            "I am learning to listen sideways", "Static blooms and then it clears", "Leave the window an inch open",
        ]),
        T("sun-within", "Sun Within", "nara", "sun-within", "track-5", "c4a46a", ["new age", "world"], "FLAC 24/192", [
            "A single tone, then the room around it", "Dust in a shaft of late gold", "The statue keeps a private sun",
            "I sit until my breath is a metronome", "Overtones climb like careful stairs", "Nothing here is in a hurry",
            "Light learns the grain of the wood", "I am not the singer, I am the hall", "Warmth from the inside of the note",
            "Hold, release, hold without gripping", "The day turns and does not announce it", "We leave the drone to finish for us",
        ]),
        T("late-signal", "Late Signal", "sable", "velvet-radio", "track-6", "8a6a62", ["noir", "downtempo"], "FLAC 24/96", [
            "On air after no one asked us to be", "Ribbon mic catching the room's old heat", "A late signal from a quieter year",
            "I say your name like a station ID", "Velvet dust on the faders", "The city answers in taxi horns",
            "Keep the light low, keep the gain honest", "We play the song that plays us back", "If you're still up, this is for you",
            "No commercials, no tomorrow", "Just the needle and the hour", "Signing off without signing off",
        ]),
        T("after-rain", "After Rain", "sable", "night-shift", "track-7", "3d5c68", ["noir", "city"], "FLAC 24/96", [
            "The street is a black piano lid", "Neon practices its handwriting", "Someone walks like they know the ending",
            "I don't, I just have the night shift", "Puddles holding spare copies of the sky", "A bus sighs at an empty stop",
            "After rain the city tells the truth", "I pocket the leftover thunder", "Your window is the only warm square",
            "I do not knock, I pass like weather", "The last train writes a silver line", "Morning will edit this out",
        ]),
        T("patchbay", "Patchbay", "copper", "copper-pulse", "track-8", "b07a4a", ["analog", "kraut"], "FLAC 24/96", [
            "Red cable into the wrong beautiful place", "The oscillator finds a cousin", "Knobs with the oil of a hundred nights",
            "We do not quantize what is already alive", "A pulse with copper in its blood", "Let the drift be the arrangement",
            "Filter opens like a slow apology", "I patch the room back into itself", "No grid, only a kind agreement",
            "When it locks, don't look at it", "The take ends when the tape does", "Leave the cables where they landed",
        ]),
        T("receding-names", "Receding Names", "tide", "low-tide", "track-9", "6a7d70", ["folk", "ambient"], "FLAC 24/88", [
            "I wrote you in the wet sand twice", "The tide is a careful editor", "Gulls argue over nothing important",
            "My guitar has salt in the wound", "Low water shows the old work", "Stones arranged by a previous weather",
            "Say it quietly, the cliff is listening", "Names recede and that is the point", "I keep a pocket of dry paper anyway",
            "The horizon does not take notes", "Walk out as far as the rules allow", "Come back lighter, come back unnamed",
        ]),
        T("ember-line", "Ember Line", "ash", "crimson-canyon", "track-10", "8a5a42", ["desert", "slowcore"], "FLAC 24/96", [
            "Heat still in the rock after sundown", "A small fire practicing being a star", "Canyon walls keep every word we waste",
            "The riff arrives like a long vehicle", "Dust on the cymbal, dust on the tongue", "We play until the bats agree",
            "Ember line across the dark wash", "I am not lost, I am between towns", "The tape machine drinks the wind",
            "Hold the last chord like a match", "Let it go before it burns you", "Drive with the windows all the way down",
        ]),
        T("ribbon-steel", "Ribbon Steel", "optic", "kinetic-dust", "track-11", "8a8680", ["electronic", "minimal"], "FLAC 24/192", [
            "A hinge decides the whole room", "Steel ribbon caught mid-thought", "Every hit is a measured kindness",
            "I sand the silence until it shines", "Kinetic dust in the studio light", "The grid is a suggestion, then a law",
            "Turn the object, hear another side", "No ornament that has no job", "We build a pulse you can lean on",
            "Then take one brick out, carefully", "The structure still stands, humming", "Leave it spinning when you go",
        ]),
        T("tunnel-bloom", "Tunnel Bloom", "optic", "afterimage", "track-12", "9aa4b0", ["experimental", "electronic"], "FLAC 24/96", [
            "Light learns the tunnel by accident", "Streaks of a train that already left", "Afterimage of a color I can't name",
            "I keep looking after it is gone", "Silver on black, then only black", "The ear invents the next station",
            "Bloom, collapse, bloom again", "We are the smear, not the bulb", "Hold still and the world draws you",
            "A long exposure of a short life", "The doors chime in a forgotten key", "Step out into ordinary night",
        ]),
        T("glass-wake", "Glass Wake", "mira", "glass-harbor", "track-13", "6a8b96", ["ambient", "chillout"], "FLAC 24/96", [
            "Morning is a pane still wet", "A boat leaves a white sentence", "I drink the quiet before the town",
            "Gulls photocopy the same complaint", "The harbor keeps last night's coins", "Wake means both rising and the trail",
            "I choose the second meaning", "Glass holds a thinner sun", "Walk until the boards are dry",
            "Name the light and let it go", "The engine starts two streets away", "We were never the only listeners",
        ]),
        T("sodium-hour", "Sodium Hour", "sable", "night-shift", "track-14", "3d5c68", ["noir", "city"], "FLAC 24/96", [
            "The lamps choose orange on purpose", "Wet asphalt practicing being a river", "A dispatcher coughs into the night",
            "I know this block by its vending hum", "Sodium hour is not quite dawn", "Taxi meters counting someone else's life",
            "Keep the window cracked for weather", "A radio two cars over finds the song", "We pretend not to notice",
            "The city files us under unfinished", "One more cigarette of rain", "Then the shift change, then the light",
        ]),
        T("wire-garden", "Wire Garden", "copper", "copper-pulse", "track-15", "b07a4a", ["analog", "synth"], "FLAC 24/96", [
            "Patch cables blooming on the floor", "A plant that runs on nine volts", "I water it with a slow LFO",
            "The filter opens like a greenhouse", "Leaves of copper, stems of clock", "Do not quantize the bees",
            "A sequence finds a vine and climbs", "Hold this voltage, it is alive", "The room smells like warm dust",
            "I name the patch after a weather", "When it drifts, that is the fruit", "Leave the garden humming overnight",
        ]),
        T("pale-radar", "Pale Radar", "optic", "afterimage", "track-16", "9aa4b0", ["minimal", "experimental"], "FLAC 24/192", [
            "A sweep that never finds the plane", "Pale green on a darkened glass", "I watch for a blip that is a memory",
            "The antenna listens harder than I do", "Every rotation is a small forgiveness", "Nothing incoming, still we wait",
            "Radar of a quieter century", "Dust in the fan, dust on the map", "A ping returns as weather",
            "I calibrate to the empty", "The screen keeps its old patience", "Sign off without turning it down",
        ]),
    ]

    static let seedPlaylists: [Playlist] = [
        .init(id: "drifting-glacier", title: "Drifting Glacier", subtitle: "Cold-water ambient for late work", color: "7aa0b4", trackIds: ["harbor-lights", "blue-hour", "sun-within", "receding-names", "tunnel-bloom", "pulse"], generated: false, createdAt: "Aug 23, 2026"),
        .init(id: "crimson-mix", title: "Crimson Canyon", subtitle: "Heat-haze and long riffs", color: "8a5a42", trackIds: ["ember-line", "patchbay", "after-rain", "ribbon-steel", "late-signal"], generated: false, createdAt: "Aug 23, 2026"),
        .init(id: "hazy-mix", title: "Hazy Monsoon", subtitle: "Rain systems and broken beats", color: "4a7a88", trackIds: ["pulse", "monsoon-static", "after-rain", "tunnel-bloom", "ribbon-steel"], generated: false, createdAt: "Aug 23, 2026"),
        .init(id: "restless-cosmos", title: "Restless Cosmos", subtitle: "Night rooftop listening", color: "5a6a88", trackIds: ["tunnel-bloom", "late-signal", "blue-hour", "sun-within", "harbor-lights", "after-rain"], generated: false, createdAt: "Aug 21, 2026"),
        .init(id: "halo", title: "Halo", subtitle: "Quiet hours, one drone at a time", color: "c4a46a", trackIds: ["sun-within", "harbor-lights", "receding-names", "blue-hour", "ribbon-steel"], generated: false, createdAt: "Aug 18, 2026"),
        .init(id: "night-drive", title: "Night Drive", subtitle: "Taste mix · generated", color: "3d5c68", trackIds: ["after-rain", "late-signal", "pulse", "patchbay", "ember-line", "tunnel-bloom", "monsoon-static"], generated: true, createdAt: "Aug 23, 2026"),
    ]

    static let friends: [Friend] = [
        .init(id: "kai", name: "Kai North", handle: "kai.north", color: "8a8680", nowPlayingId: "pulse", scrobbles: 4821, topTrackIds: ["pulse", "ribbon-steel", "patchbay", "monsoon-static"], recentIds: ["pulse", "ribbon-steel", "tunnel-bloom"], topArtistIds: ["optic", "lumen", "copper"], bio: "Malmö. Collects hinges and kick drums."),
        .init(id: "juniper", name: "Juniper Hale", handle: "juniper", color: "6a7d70", nowPlayingId: "receding-names", scrobbles: 3102, topTrackIds: ["receding-names", "blue-hour", "sun-within", "harbor-lights"], recentIds: ["receding-names", "blue-hour", "glass-wake"], topArtistIds: ["tide", "mira", "nara"], bio: "Writes the names the water erases."),
        .init(id: "rafi", name: "Rafi Wave", handle: "rafi.wave", color: "8a6a62", nowPlayingId: "late-signal", scrobbles: 7640, topTrackIds: ["late-signal", "after-rain", "ember-line", "tunnel-bloom"], recentIds: ["late-signal", "after-rain", "sodium-hour"], topArtistIds: ["sable", "ash", "optic"], bio: "Still on the night shift."),
    ]

    static let genres = ["ambient", "electronic", "new age", "noir", "analog", "folk", "desert", "chillout", "world", "minimal", "experimental", "city"]

    static let profileName = "Shihas"
    static let profileHandle = "shihas"

    static var cloud: [String: Track] = [:]

    static func ingest(_ list: [Track]) {
        for t in list { cloud[t.id] = t }
    }

    static func track(_ id: String) -> Track? { tracks.first { $0.id == id } ?? cloud[id] }
    static func artist(_ id: String) -> Artist? { artists.first { $0.id == id } }
    static func album(_ id: String) -> Album? { albums.first { $0.id == id } }
    static func artistName(_ id: String) -> String {
        if let a = artist(id) { return a.name }
        if let t = cloud[id] { return t.artistLabel ?? "Unknown" }
        if let t = cloud.values.first(where: { $0.artistId == id }) { return t.artistLabel ?? "Unknown" }
        return "Unknown"
    }
    static func albumTitle(_ id: String) -> String { album(id)?.title ?? (id == "audius" ? "Audius" : "") }
    static func tracks(album id: String) -> [Track] { tracks.filter { $0.albumId == id } }
    static func tracks(artist id: String) -> [Track] { tracks.filter { $0.artistId == id } }
    static func albums(artist id: String) -> [Album] { albums.filter { $0.artistId == id } }

    static func color(for id: String) -> String {
        let palette = ["6a8b96", "4a7a88", "c4a46a", "8a6a62", "3d5c68", "b07a4a", "6a7d70", "8a5a42", "8a8680", "9aa4b0"]
        let i = abs(id.hashValue) % palette.count
        return palette[i]
    }

    static func compatibility(friend: Friend, liked: Set<String>, recent: [String]) -> Int {
        let mine = liked.union(recent.prefix(12))
        let theirs = Set(friend.topTrackIds + friend.recentIds)
        let hit = theirs.filter { mine.contains($0) }.count
        var myG = Set<String>(), theirG = Set<String>()
        for id in mine { track(id)?.genres.forEach { myG.insert($0) } }
        for id in theirs { track(id)?.genres.forEach { theirG.insert($0) } }
        let gHit = theirG.filter { myG.contains($0) }.count
        let score = 38 + Int(Double(hit) / Double(max(theirs.count, 1)) * 32) + Int(Double(gHit) / Double(max(theirG.count, 1)) * 30)
        return min(99, max(12, score))
    }

    private static func T(_ id: String, _ title: String, _ artist: String, _ album: String, _ file: String, _ color: String, _ genres: [String], _ quality: String, _ lyrics: [String]) -> Track {
        Track(id: id, title: title, artistId: artist, albumId: album, audioFile: file, duration: 95, genres: genres, quality: quality, color: color, lyrics: L(lyrics))
    }
}
