//
//  MixesData.swift
//  MoodistMac
//
//  Default thematic mixes from moodist_presets_en_perfected.md. Volumes are 0.0...1.0.
//

import Foundation

private func v(_ pct: Int) -> Double { Double(pct) / 100 }

enum MixesData {
    static let categories: [MixCategory] = [
        custom,
        natureRelaxation,
        walking,
        seaCoast,
        forestFireNight,
        rainStorm,
        focusStudy,
        travelMotion,
        sleepNoise,
        placesAmbience
    ]

    /// Diccionario estático para búsquedas O(1) de mixes por ID (evita duplicar en vistas).
    static let allMixesById: [String: Mix] = Dictionary(uniqueKeysWithValues: categories.flatMap(\.mixes).map { ($0.id, $0) })

    // MARK: - Custom (0)
    static let custom = MixCategory(
        id: "custom",
        title: "Custom Mixes",
        iconName: "square.and.pencil",
        mixes: []
    )

    // MARK: - Nature & Relaxation (8)
    static let natureRelaxation = MixCategory(
        id: "nature-relaxation",
        title: "Nature & Relaxation",
        iconName: "leaf.fill",
        mixes: [
            Mix(id: "zen-garden", name: "Zen Garden", iconName: "leaf.fill", soundIds: ["river", "wind-chimes", "birds", "wind-in-trees", "pink-noise"], volumes: ["river": v(55), "wind-chimes": v(35), "birds": v(25), "wind-in-trees": v(20), "pink-noise": v(10)]),
            Mix(id: "morning-river", name: "Morning River", iconName: "sunrise.fill", soundIds: ["river", "birds", "wind", "wind-in-trees", "pink-noise"], volumes: ["river": v(65), "birds": v(35), "wind": v(20), "wind-in-trees": v(20), "pink-noise": v(10)]),
            Mix(id: "meadow-breeze", name: "Meadow Breeze", iconName: "wind", soundIds: ["wind", "river", "birds", "wind-chimes", "pink-noise"], volumes: ["wind": v(45), "river": v(25), "birds": v(25), "wind-chimes": v(20), "pink-noise": v(10)]),
            Mix(id: "distant-falls", name: "Distant Falls", iconName: "drop.fill", soundIds: ["river", "wind-in-trees", "wind", "birds", "pink-noise"], volumes: ["river": v(87), "wind-in-trees": v(87), "wind": v(55), "birds": v(22), "pink-noise": v(12)]),
            Mix(id: "sunset-birds", name: "Sunset Birds", iconName: "bird.fill", soundIds: ["birds", "river", "wind-chimes", "wind-in-trees", "pink-noise"], volumes: ["birds": v(55), "river": v(30), "wind-chimes": v(20), "wind-in-trees": v(15), "pink-noise": v(10)]),
            Mix(id: "japanese-garden", name: "Japanese Garden", iconName: "leaf.circle.fill", soundIds: ["wind-chimes", "river", "birds", "wind", "pink-noise"], volumes: ["wind-chimes": v(45), "river": v(35), "birds": v(15), "wind": v(15), "pink-noise": v(10)]),
            Mix(id: "river-meditation", name: "River Meditation", iconName: "waveform.path.ecg", soundIds: ["river", "pink-noise", "wind-chimes", "wind", "birds"], volumes: ["river": v(55), "pink-noise": v(30), "wind-chimes": v(15), "wind": v(10), "birds": v(10)]),
            Mix(id: "waterfall-shrine", name: "Waterfall Shrine", iconName: "drop.fill", soundIds: ["waterfall", "droplets", "temple", "singing-bowl", "wind-in-trees"], volumes: ["waterfall": v(60), "droplets": v(35), "temple": v(25), "singing-bowl": v(20), "wind-in-trees": v(15)]),
            Mix(id: "jungle-dawn-relay", name: "Jungle Dawn Relay", iconName: "sunrise.fill", soundIds: ["jungle", "birds", "beehive", "river", "droplets"], volumes: ["jungle": v(75), "birds": v(75), "beehive": v(75), "river": v(40), "droplets": v(40)]),
            Mix(id: "rain-on-leaves-river", name: "Rain on Leaves, River Under", iconName: "leaf", soundIds: ["rain-on-leaves", "river", "wind-in-trees", "droplets", "wind"], volumes: ["rain-on-leaves": v(50), "river": v(40), "wind-in-trees": v(30), "droplets": v(20), "wind": v(10)])
        ]
    )

    // MARK: - Walking (4)
    static let walking = MixCategory(
        id: "walking",
        title: "Walking",
        iconName: "figure.walk",
        mixes: [
            Mix(id: "forest-walk", name: "Forest Walk", iconName: "tree.fill", soundIds: ["wind-in-trees", "birds", "wind", "river", "walk-on-leaves", "pink-noise"], volumes: ["wind-in-trees": v(60), "birds": v(25), "wind": v(20), "river": v(20), "walk-on-leaves": v(40), "pink-noise": v(10)]),
            Mix(id: "glacier-footsteps", name: "Glacier Footsteps", iconName: "snowflake", soundIds: ["walk-in-snow", "howling-wind", "wind-in-trees", "wind"], volumes: ["walk-in-snow": v(65), "howling-wind": v(40), "wind-in-trees": v(20), "wind": v(15)]),
            Mix(id: "autumn-footpath", name: "Autumn Footpath", iconName: "leaf.fill", soundIds: ["walk-on-leaves", "wind-in-trees", "birds", "droplets"], volumes: ["walk-on-leaves": v(55), "wind-in-trees": v(45), "birds": v(25), "droplets": v(15)]),
            Mix(id: "gravel-miles", name: "Gravel Miles", iconName: "figure.walk", soundIds: ["walk-on-gravel", "road", "traffic", "wind", "clock"], volumes: ["walk-on-gravel": v(75), "road": v(75), "traffic": v(75), "wind": v(25), "clock": v(25)])
        ]
    )

    // MARK: - Sea & Coast (8)
    static let seaCoast = MixCategory(
        id: "sea-coast",
        title: "Sea & Coast",
        iconName: "sun.max.fill",
        mixes: [
            Mix(id: "calm-beach", name: "Calm Beach", iconName: "sun.max.fill", soundIds: ["waves", "wind", "seagulls", "pink-noise"], volumes: ["waves": v(65), "wind": v(25), "seagulls": v(15), "pink-noise": v(10)]),
            Mix(id: "windy-coast", name: "Windy Coast", iconName: "wind", soundIds: ["waves", "wind", "seagulls", "pink-noise"], volumes: ["waves": v(55), "wind": v(55), "seagulls": v(10), "pink-noise": v(10)]),
            Mix(id: "harbor-sunrise", name: "Harbor Sunrise", iconName: "sunrise.fill", soundIds: ["waves", "seagulls", "wind", "pink-noise"], volumes: ["waves": v(77), "seagulls": v(42), "wind": v(57), "pink-noise": v(17)]),
            Mix(id: "quiet-bay", name: "Quiet Bay", iconName: "drop.fill", soundIds: ["waves", "river", "wind", "seagulls"], volumes: ["waves": v(45), "river": v(30), "wind": v(15), "seagulls": v(10)]),
            Mix(id: "deep-waves", name: "Deep Waves", iconName: "waveform", soundIds: ["waves", "pink-noise", "wind"], volumes: ["waves": v(77), "pink-noise": v(22), "wind": v(42)]),
            Mix(id: "distant-seagulls", name: "Distant Seagulls", iconName: "bird.fill", soundIds: ["waves", "seagulls", "wind", "pink-noise"], volumes: ["waves": v(50), "seagulls": v(35), "wind": v(20), "pink-noise": v(10)]),
            Mix(id: "sea-window", name: "Sea Window", iconName: "rectangle.portrait.and.arrow.right", soundIds: ["rain-on-window", "waves", "wind", "pink-noise", "seagulls"], volumes: ["rain-on-window": v(50), "waves": v(45), "wind": v(20), "pink-noise": v(10), "seagulls": v(10)]),
            Mix(id: "ocean-storm", name: "Ocean Storm", iconName: "cloud.bolt.rain.fill", soundIds: ["waves", "heavy-rain", "rain-on-window", "thunder", "wind", "pink-noise"], volumes: ["waves": v(55), "heavy-rain": v(45), "rain-on-window": v(25), "thunder": v(25), "wind": v(20), "pink-noise": v(15)])
        ]
    )

    // MARK: - Forest, Fire & Night (8)
    static let forestFireNight = MixCategory(
        id: "forest-fire-night",
        title: "Forest, Fire & Night",
        iconName: "flame.fill",
        mixes: [
            Mix(id: "night-camp", name: "Night Camp", iconName: "flame.fill", soundIds: ["campfire", "crickets", "wind-in-trees", "pink-noise", "wind"], volumes: ["campfire": v(72), "crickets": v(62), "wind-in-trees": v(57), "pink-noise": v(22), "wind": v(32)]),
            Mix(id: "soft-campfire", name: "Soft Campfire", iconName: "flame", soundIds: ["campfire", "wind-in-trees", "crickets", "pink-noise"], volumes: ["campfire": v(77), "wind-in-trees": v(22), "crickets": v(77), "pink-noise": v(0)]),
            Mix(id: "crickets-breeze", name: "Crickets & Breeze", iconName: "moon.stars.fill", soundIds: ["crickets", "wind-in-trees", "wind", "pink-noise"], volumes: ["crickets": v(75), "wind-in-trees": v(25), "wind": v(0), "pink-noise": v(0)]),
            Mix(id: "forest-cabin", name: "Forest Cabin", iconName: "house.fill", soundIds: ["rain-on-window", "campfire", "wind-in-trees", "wind", "pink-noise"], volumes: ["rain-on-window": v(75), "campfire": v(90), "wind-in-trees": v(35), "wind": v(20), "pink-noise": v(10)]),
            Mix(id: "night-river", name: "Night River", iconName: "moon.fill", soundIds: ["river", "crickets", "wind", "wind-in-trees", "pink-noise"], volumes: ["river": v(67), "crickets": v(50), "wind": v(37), "wind-in-trees": v(67), "pink-noise": v(22)]),
            Mix(id: "deep-night-forest", name: "Deep Night Forest", iconName: "sparkles", soundIds: ["wind-in-trees", "crickets", "wind"], volumes: ["wind-in-trees": v(65), "crickets": v(50), "wind": v(15)]),
            Mix(id: "storm-camp", name: "Storm Camp", iconName: "cloud.bolt.rain.fill", soundIds: ["heavy-rain", "campfire", "rain-on-window", "thunder", "wind-in-trees"], volumes: ["heavy-rain": v(62), "campfire": v(62), "rain-on-window": v(32), "thunder": v(87), "wind-in-trees": v(32)]),
            Mix(id: "fire-chimes", name: "Fire & Chimes", iconName: "bell.fill", soundIds: ["campfire", "wind-chimes", "wind-in-trees", "crickets", "pink-noise"], volumes: ["campfire": v(50), "wind-chimes": v(30), "wind-in-trees": v(25), "crickets": v(15), "pink-noise": v(10)])
        ]
    )

    // MARK: - Rain & Storm (8)
    static let rainStorm = MixCategory(
        id: "rain-storm",
        title: "Rain & Storm",
        iconName: "cloud.rain.fill",
        mixes: [
            Mix(id: "rainy-afternoon", name: "Rainy Afternoon", iconName: "cloud.rain.fill", soundIds: ["heavy-rain", "rain-on-window", "thunder", "wind", "pink-noise"], volumes: ["heavy-rain": v(65), "rain-on-window": v(55), "thunder": v(20), "wind": v(15), "pink-noise": v(10)]),
            Mix(id: "soft-window-rain", name: "Soft Window Rain", iconName: "cloud.drizzle.fill", soundIds: ["light-rain", "rain-on-window", "pink-noise", "wind"], volumes: ["light-rain": v(65), "rain-on-window": v(60), "pink-noise": v(15), "wind": v(10)]),
            Mix(id: "distant-thunderstorm", name: "Distant Thunderstorm", iconName: "cloud.bolt.fill", soundIds: ["heavy-rain", "rain-on-window", "wind", "thunder", "pink-noise"], volumes: ["heavy-rain": v(55), "rain-on-window": v(30), "wind": v(30), "thunder": v(15), "pink-noise": v(10)]),
            Mix(id: "heavy-storm", name: "Heavy Storm", iconName: "cloud.bolt.rain.fill", soundIds: ["heavy-rain", "rain-on-window", "thunder", "howling-wind", "pink-noise"], volumes: ["heavy-rain": v(77), "rain-on-window": v(22), "thunder": v(77), "howling-wind": v(65), "pink-noise": v(12)]),
            Mix(id: "forest-rain", name: "Forest Rain", iconName: "tree.fill", soundIds: ["light-rain", "wind-in-trees", "wind", "river", "pink-noise"], volumes: ["light-rain": v(55), "wind-in-trees": v(45), "wind": v(20), "river": v(15), "pink-noise": v(10)]),
            Mix(id: "rain-river", name: "Rain + River", iconName: "drop.fill", soundIds: ["light-rain", "river", "rain-on-window", "wind", "pink-noise"], volumes: ["light-rain": v(67), "river": v(87), "rain-on-window": v(47), "wind": v(27), "pink-noise": v(42)]),
            Mix(id: "tentstorm-shelter", name: "Tentstorm Shelter", iconName: "tent.fill", soundIds: ["rain-on-tent", "howling-wind", "heavy-rain", "thunder", "wolf"], volumes: ["rain-on-tent": v(65), "howling-wind": v(30), "heavy-rain": v(25), "thunder": v(15), "wolf": v(18)]),
            Mix(id: "cathedral-drizzle", name: "Cathedral Drizzle", iconName: "building.columns.fill", soundIds: ["church", "rain-on-window", "light-rain", "singing-bowl", "wind"], volumes: ["church": v(77), "rain-on-window": v(50), "light-rain": v(50), "singing-bowl": v(75), "wind": v(50)])
        ]
    )

    // MARK: - Focus & Study (8)
    static let focusStudy = MixCategory(
        id: "focus-study",
        title: "Focus & Study",
        iconName: "book.fill",
        mixes: [
            Mix(id: "productive-cafe", name: "Productive Cafe", iconName: "cup.and.saucer.fill", soundIds: ["cafe", "light-rain", "pink-noise"], volumes: ["cafe": v(82), "light-rain": v(22), "pink-noise": v(22)]),
            Mix(id: "library", name: "Library", iconName: "book.fill", soundIds: ["library", "paper", "clock"], volumes: ["library": v(50), "paper": v(25), "clock": v(75)]),
            Mix(id: "rainy-library", name: "Rainy Library", iconName: "books.vertical.fill", soundIds: ["library", "clock", "paper"], volumes: ["library": v(75), "clock": v(75), "paper": v(25)]),
            Mix(id: "focused-writing", name: "Focused Writing", iconName: "pencil.and.outline", soundIds: ["paper", "clock", "pink-noise", "library"], volumes: ["paper": v(55), "clock": v(25), "pink-noise": v(25), "library": v(20)]),
            Mix(id: "cafe-by-the-sea", name: "Cafe by the Sea", iconName: "cup.and.saucer", soundIds: ["cafe", "waves", "seagulls"], volumes: ["cafe": v(50), "waves": v(50), "seagulls": v(50)]),
            Mix(id: "morse-focus-protocol", name: "Morse Focus Protocol", iconName: "dot.radiowaves.left.and.right", soundIds: ["morse-code", "typewriter", "paper", "clock", "library", "tuning-radio"], volumes: ["morse-code": v(25), "typewriter": v(30), "paper": v(30), "clock": v(20), "library": v(20), "tuning-radio": v(10)]),
            Mix(id: "office-late-hours", name: "Office Late Hours", iconName: "desktopcomputer", soundIds: ["office", "keyboard", "clock", "paper", "rain-on-window"], volumes: ["office": v(85), "keyboard": v(35), "clock": v(65), "paper": v(35), "rain-on-window": v(15)]),
        ]
    )

    // MARK: - Travel & Motion (8)
    static let travelMotion = MixCategory(
        id: "travel-motion",
        title: "Travel & Motion",
        iconName: "tram.fill",
        mixes: [
            // Trail Riding
            Mix(id: "forest-trail-canter", name: "Forest Trail Canter", iconName: "leaf.fill", soundIds: ["horse-gallop", "walk-on-leaves", "wind-in-trees", "birds", "wind"], volumes: ["horse-gallop": v(55), "walk-on-leaves": v(45), "wind-in-trees": v(35), "birds": v(25), "wind": v(10)]),
            Mix(id: "riverside-trot", name: "Riverside Trot", iconName: "water.waves", soundIds: ["river", "horse-gallop", "walk-on-gravel", "birds", "wind-in-trees"], volumes: ["river": v(55), "horse-gallop": v(45), "walk-on-gravel": v(25), "birds": v(20), "wind-in-trees": v(15)]),
            Mix(id: "meadow-gallop", name: "Meadow Gallop", iconName: "wind", soundIds: ["horse-gallop", "wind", "birds", "wind-in-trees", "pink-noise"], volumes: ["horse-gallop": v(60), "wind": v(40), "birds": v(20), "wind-in-trees": v(15), "pink-noise": v(10)]),
            Mix(id: "jungle-trail", name: "Jungle Trail", iconName: "tree.fill", soundIds: ["jungle", "horse-gallop", "birds", "droplets", "beehive"], volumes: ["jungle": v(45), "horse-gallop": v(40), "birds": v(25), "droplets": v(20), "beehive": v(10)]),
            Mix(id: "waterfall-pass", name: "Waterfall Pass", iconName: "drop.fill", soundIds: ["waterfall", "horse-gallop", "wind-in-trees", "droplets", "wind"], volumes: ["waterfall": v(45), "horse-gallop": v(40), "wind-in-trees": v(25), "droplets": v(20), "wind": v(10)]),
            Mix(id: "gravel-path-ride", name: "Gravel Path Ride", iconName: "figure.walk", soundIds: ["walk-on-gravel", "wind", "birds", "road"], volumes: ["walk-on-gravel": v(50), "wind": v(40), "birds": v(50), "road": v(10)]),
            // Mindful Riding
            Mix(id: "mindful-walk", name: "Mindful Walk", iconName: "leaf.circle.fill", soundIds: ["binaural-theta", "river", "wind-in-trees", "birds", "walk-on-gravel"], volumes: ["binaural-theta": v(77), "river": v(55), "wind-in-trees": v(55), "birds": v(55), "walk-on-gravel": v(55)]),
            // Weather Rides
            Mix(id: "light-rain-ride", name: "Light Rain Ride", iconName: "cloud.drizzle.fill", soundIds: ["light-rain", "rain-on-leaves", "horse-gallop", "wind-in-trees", "wind"], volumes: ["light-rain": v(55), "rain-on-leaves": v(35), "horse-gallop": v(40), "wind-in-trees": v(25), "wind": v(10)]),
            Mix(id: "storm-ride", name: "Storm Ride", iconName: "cloud.bolt.rain.fill", soundIds: ["heavy-rain", "horse-gallop", "wind", "thunder", "rain-on-leaves"], volumes: ["heavy-rain": v(50), "horse-gallop": v(35), "wind": v(30), "thunder": v(15), "rain-on-leaves": v(15)]),
            Mix(id: "winter-trail", name: "Winter Trail", iconName: "snowflake", soundIds: ["horse-gallop", "howling-wind", "wind-in-trees", "wind"], volumes: ["horse-gallop": v(40), "howling-wind": v(30), "wind-in-trees": v(15), "wind": v(10)]),
            // Coastal & Night Rides
            Mix(id: "beach-ride", name: "Beach Ride", iconName: "sun.max.fill", soundIds: ["waves", "horse-gallop", "wind", "seagulls", "pink-noise"], volumes: ["waves": v(60), "horse-gallop": v(45), "wind": v(25), "seagulls": v(30), "pink-noise": v(10)]),
            Mix(id: "night-ride", name: "Night Ride", iconName: "moon.fill", soundIds: ["wind-in-trees", "crickets", "horse-gallop", "owl", "pink-noise"], volumes: ["wind-in-trees": v(75), "crickets": v(75), "horse-gallop": v(45), "owl": v(70), "pink-noise": v(45)]),
            // Existing train, boat, transport mixes
            Mix(id: "train-journey", name: "Train Journey", iconName: "tram.fill", soundIds: ["inside-a-train", "rain-on-window", "pink-noise", "wind"], volumes: ["inside-a-train": v(67), "rain-on-window": v(47), "pink-noise": v(47), "wind": v(47)]),
            Mix(id: "night-train", name: "Night Train", iconName: "moon.fill", soundIds: ["inside-a-train", "pink-noise", "rain-on-window", "wind"], volumes: ["inside-a-train": v(82), "pink-noise": v(32), "rain-on-window": v(62), "wind": v(22)]),
            Mix(id: "coastal-ride", name: "Coastal Ride", iconName: "water.waves", soundIds: ["inside-a-train", "waves", "seagulls", "wind", "rain-on-window"], volumes: ["inside-a-train": v(80), "waves": v(60), "seagulls": v(40), "wind": v(20), "rain-on-window": v(20)]),
            Mix(id: "quiet-carriage", name: "Quiet Carriage", iconName: "speaker.slash.fill", soundIds: ["inside-a-train", "pink-noise", "rain-on-window"], volumes: ["inside-a-train": v(33), "pink-noise": v(0), "rain-on-window": v(33)]),
            Mix(id: "cafe-commute", name: "Cafe Commute", iconName: "cup.and.saucer.fill", soundIds: ["inside-a-train", "cafe", "paper", "rain-on-window", "pink-noise"], volumes: ["inside-a-train": v(60), "cafe": v(50), "paper": v(40), "rain-on-window": v(40), "pink-noise": v(10)]),
            Mix(id: "subway-umbrella-rush", name: "Subway Umbrella Rush", iconName: "tram.fill", soundIds: ["subway-station", "rain-on-umbrella", "busy-street", "traffic", "wind"], volumes: ["subway-station": v(72), "rain-on-umbrella": v(42), "busy-street": v(62), "traffic": v(72), "wind": v(22)]),
            Mix(id: "airplane-cruise", name: "Airplane Cruise", iconName: "airplane", soundIds: ["airplane", "airport", "pink-noise", "wind", "rain-on-window"], volumes: ["airplane": v(72), "airport": v(32), "pink-noise": v(42), "wind": v(72), "rain-on-window": v(12)]),
            Mix(id: "sailboat-lullaby", name: "Sailboat Lullaby", iconName: "sailboat.fill", soundIds: ["sailboat", "waves", "wind", "seagulls"], volumes: ["sailboat": v(90), "waves": v(50), "wind": v(30), "seagulls": v(90)]),
            Mix(id: "submarine-drift", name: "Submarine Drift", iconName: "water.waves", soundIds: ["submarine", "underwater", "bubbles", "whale", "waves"], volumes: ["submarine": v(72), "underwater": v(62), "bubbles": v(42), "whale": v(72), "waves": v(42)]),
            Mix(id: "rowing-at-dawn", name: "Rowing at Dawn", iconName: "sunrise", soundIds: ["rowing-boat", "river", "seagulls", "wind", "droplets"], volumes: ["rowing-boat": v(55), "river": v(40), "seagulls": v(20), "wind": v(15), "droplets": v(10)])
        ]
    )

    // MARK: - Sleep & Noise (8)
    static let sleepNoise = MixCategory(
        id: "sleep-noise",
        title: "Sleep & Noise",
        iconName: "moon.zzz.fill",
        mixes: [
            Mix(id: "deep-sleep", name: "Deep Sleep", iconName: "moon.zzz.fill", soundIds: ["pink-noise", "waves", "heavy-rain", "rain-on-window", "wind"], volumes: ["pink-noise": v(50), "waves": v(35), "heavy-rain": v(25), "rain-on-window": v(20), "wind": v(10)]),
            Mix(id: "pure-pink-noise", name: "Pure Pink Noise", iconName: "waveform.circle.fill", soundIds: ["pink-noise"], volumes: ["pink-noise": v(80)]),
            Mix(id: "rain-sleep", name: "Rain Sleep", iconName: "cloud.moon.rain.fill", soundIds: ["pink-noise", "light-rain", "rain-on-window", "wind", "thunder"], volumes: ["pink-noise": v(40), "light-rain": v(45), "rain-on-window": v(45), "wind": v(10), "thunder": v(5)]),
            Mix(id: "ocean-sleep", name: "Ocean Sleep", iconName: "moon.circle.fill", soundIds: ["waves", "pink-noise", "wind"], volumes: ["waves": v(60), "pink-noise": v(35), "wind": v(15)]),
            Mix(id: "forest-sleep", name: "Forest Sleep", iconName: "leaf.fill", soundIds: ["wind-in-trees", "pink-noise", "crickets", "wind"], volumes: ["wind-in-trees": v(50), "pink-noise": v(35), "crickets": v(25), "wind": v(10)]),
            Mix(id: "river-nap", name: "River Nap", iconName: "zzz", soundIds: ["river", "pink-noise", "wind", "birds"], volumes: ["river": v(55), "pink-noise": v(35), "wind": v(15), "birds": v(10)]),
            Mix(id: "window-night", name: "Window Night", iconName: "window.ceiling", soundIds: ["rain-on-window", "pink-noise", "wind", "crickets", "thunder"], volumes: ["rain-on-window": v(65), "pink-noise": v(35), "wind": v(10), "crickets": v(10), "thunder": v(8)]),
            Mix(id: "soft-isolation", name: "Soft Isolation", iconName: "ear.and.waveform", soundIds: ["pink-noise", "wind", "waves", "rain-on-window"], volumes: ["pink-noise": v(70), "wind": v(15), "waves": v(15), "rain-on-window": v(10)])
        ]
    )

    // MARK: - Places & Ambience (8)
    static let placesAmbience = MixCategory(
        id: "places-ambience",
        title: "Places & Ambience",
        iconName: "mappin.circle.fill",
        mixes: [
            Mix(id: "owl-at-the-temple", name: "Owl at the Temple", iconName: "moon.stars.fill", soundIds: ["temple", "owl", "wind-in-trees", "singing-bowl", "droplets"], volumes: ["temple": v(45), "owl": v(30), "wind-in-trees": v(30), "singing-bowl": v(20), "droplets": v(10)]),
            Mix(id: "analog-lab-session", name: "Analog Lab Session", iconName: "testtube.2", soundIds: ["laboratory", "tuning-radio", "keyboard", "typewriter", "vinyl-effect"], volumes: ["laboratory": v(45), "tuning-radio": v(25), "keyboard": v(25), "typewriter": v(15), "vinyl-effect": v(15)]),
            Mix(id: "laundry-spin-calm", name: "Laundry Spin Calm", iconName: "washer.fill", soundIds: ["washing-machine", "dryer", "laundry-room", "ceiling-fan", "wind"], volumes: ["washing-machine": v(45), "dryer": v(35), "laundry-room": v(30), "ceiling-fan": v(20), "wind": v(10)]),
            Mix(id: "carousel-dreams", name: "Carousel Dreams", iconName: "sparkles", soundIds: ["carousel", "bubbles", "crowd", "vinyl-effect"], volumes: ["carousel": v(45), "bubbles": v(35), "crowd": v(20), "vinyl-effect": v(15)]),
            Mix(id: "afterhours-bar-hush", name: "Afterhours Bar Hush", iconName: "music.note", soundIds: ["crowded-bar", "crowd", "busy-street", "traffic", "vinyl-effect"], volumes: ["crowded-bar": v(55), "crowd": v(25), "busy-street": v(20), "traffic": v(15), "vinyl-effect": v(10)]),
            Mix(id: "night-village-receiver", name: "Night Village Receiver", iconName: "antenna.radiowaves.left.and.right", soundIds: ["night-village", "tuning-radio", "crickets", "wind-in-trees", "vinyl-effect"], volumes: ["night-village": v(55), "tuning-radio": v(25), "crickets": v(20), "wind-in-trees": v(15), "vinyl-effect": v(10)]),
            Mix(id: "construction-flow-state", name: "Construction Flow State", iconName: "hammer.fill", soundIds: ["construction-site", "road", "traffic", "clock", "wind"], volumes: ["construction-site": v(55), "road": v(25), "traffic": v(25), "clock": v(10), "wind": v(10)])
        ]
    )
}
