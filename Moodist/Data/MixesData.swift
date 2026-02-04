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
            Mix(id: "distant-falls", name: "Distant Falls", iconName: "drop.fill", soundIds: ["river", "wind-in-trees", "wind", "birds", "pink-noise"], volumes: ["river": v(70), "wind-in-trees": v(35), "wind": v(15), "birds": v(15), "pink-noise": v(10)]),
            Mix(id: "sunset-birds", name: "Sunset Birds", iconName: "bird.fill", soundIds: ["birds", "river", "wind-chimes", "wind-in-trees", "pink-noise"], volumes: ["birds": v(55), "river": v(30), "wind-chimes": v(20), "wind-in-trees": v(15), "pink-noise": v(10)]),
            Mix(id: "japanese-garden", name: "Japanese Garden", iconName: "leaf.circle.fill", soundIds: ["wind-chimes", "river", "birds", "wind", "pink-noise"], volumes: ["wind-chimes": v(45), "river": v(35), "birds": v(15), "wind": v(15), "pink-noise": v(10)]),
            Mix(id: "river-meditation", name: "River Meditation", iconName: "waveform.path.ecg", soundIds: ["river", "pink-noise", "wind-chimes", "wind", "birds"], volumes: ["river": v(55), "pink-noise": v(30), "wind-chimes": v(15), "wind": v(10), "birds": v(10)]),
            Mix(id: "waterfall-shrine", name: "Waterfall Shrine", iconName: "drop.fill", soundIds: ["waterfall", "droplets", "temple", "singing-bowl", "wind-in-trees"], volumes: ["waterfall": v(60), "droplets": v(35), "temple": v(25), "singing-bowl": v(20), "wind-in-trees": v(15)]),
            Mix(id: "jungle-dawn-relay", name: "Jungle Dawn Relay", iconName: "sunrise.fill", soundIds: ["jungle", "birds", "beehive", "river", "droplets"], volumes: ["jungle": v(55), "birds": v(30), "beehive": v(20), "river": v(20), "droplets": v(10)]),
            Mix(id: "rain-on-leaves-river", name: "Rain on Leaves, River Under", iconName: "leaf", soundIds: ["rain-on-leaves", "river", "wind-in-trees", "droplets", "wind"], volumes: ["rain-on-leaves": v(50), "river": v(40), "wind-in-trees": v(30), "droplets": v(20), "wind": v(10)])
        ]
    )

    // MARK: - Walking (4)
    static let walking = MixCategory(
        id: "walking",
        title: "Walking",
        iconName: "figure.walk",
        mixes: [
            Mix(id: "forest-walk", name: "Forest Walk", iconName: "tree.fill", soundIds: ["wind-in-trees", "birds", "wind", "river", "pink-noise"], volumes: ["wind-in-trees": v(60), "birds": v(25), "wind": v(20), "river": v(20), "pink-noise": v(10)]),
            Mix(id: "glacier-footsteps", name: "Glacier Footsteps", iconName: "snowflake", soundIds: ["walk-in-snow", "howling-wind", "wind-in-trees", "wind"], volumes: ["walk-in-snow": v(65), "howling-wind": v(40), "wind-in-trees": v(20), "wind": v(15)]),
            Mix(id: "autumn-footpath", name: "Autumn Footpath", iconName: "leaf.fill", soundIds: ["walk-on-leaves", "wind-in-trees", "birds", "droplets"], volumes: ["walk-on-leaves": v(55), "wind-in-trees": v(45), "birds": v(25), "droplets": v(15)]),
            Mix(id: "gravel-miles", name: "Gravel Miles", iconName: "figure.walk", soundIds: ["walk-on-gravel", "road", "traffic", "wind", "clock"], volumes: ["walk-on-gravel": v(55), "road": v(35), "traffic": v(25), "wind": v(20), "clock": v(10)])
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
            Mix(id: "harbor-sunrise", name: "Harbor Sunrise", iconName: "sunrise.fill", soundIds: ["waves", "seagulls", "wind", "pink-noise"], volumes: ["waves": v(50), "seagulls": v(30), "wind": v(20), "pink-noise": v(10)]),
            Mix(id: "quiet-bay", name: "Quiet Bay", iconName: "drop.fill", soundIds: ["waves", "river", "wind", "seagulls", "pink-noise"], volumes: ["waves": v(45), "river": v(30), "wind": v(15), "seagulls": v(10), "pink-noise": v(10)]),
            Mix(id: "deep-waves", name: "Deep Waves", iconName: "waveform", soundIds: ["waves", "pink-noise", "wind"], volumes: ["waves": v(75), "pink-noise": v(25), "wind": v(15)]),
            Mix(id: "distant-seagulls", name: "Distant Seagulls", iconName: "bird.fill", soundIds: ["waves", "seagulls", "wind", "pink-noise"], volumes: ["waves": v(50), "seagulls": v(35), "wind": v(20), "pink-noise": v(10)]),
            Mix(id: "sea-window", name: "Sea Window", iconName: "rectangle.portrait.and.arrow.right", soundIds: ["rain-on-window", "waves", "wind", "pink-noise", "seagulls"], volumes: ["rain-on-window": v(50), "waves": v(45), "wind": v(20), "pink-noise": v(10), "seagulls": v(10)]),
            Mix(id: "ocean-storm", name: "Ocean Storm", iconName: "cloud.bolt.rain.fill", soundIds: ["waves", "heavy-rain", "rain-on-window", "thunder", "wind"], volumes: ["waves": v(55), "heavy-rain": v(45), "rain-on-window": v(25), "thunder": v(25), "wind": v(20)])
        ]
    )

    // MARK: - Forest, Fire & Night (8)
    static let forestFireNight = MixCategory(
        id: "forest-fire-night",
        title: "Forest, Fire & Night",
        iconName: "flame.fill",
        mixes: [
            Mix(id: "night-camp", name: "Night Camp", iconName: "flame.fill", soundIds: ["campfire", "crickets", "wind-in-trees", "pink-noise", "wind"], volumes: ["campfire": v(70), "crickets": v(40), "wind-in-trees": v(25), "pink-noise": v(10), "wind": v(10)]),
            Mix(id: "soft-campfire", name: "Soft Campfire", iconName: "flame", soundIds: ["campfire", "wind-in-trees", "crickets", "pink-noise"], volumes: ["campfire": v(65), "wind-in-trees": v(30), "crickets": v(20), "pink-noise": v(10)]),
            Mix(id: "crickets-breeze", name: "Crickets & Breeze", iconName: "moon.stars.fill", soundIds: ["crickets", "wind-in-trees", "wind", "pink-noise"], volumes: ["crickets": v(60), "wind-in-trees": v(35), "wind": v(20), "pink-noise": v(10)]),
            Mix(id: "forest-cabin", name: "Forest Cabin", iconName: "house.fill", soundIds: ["rain-on-window", "campfire", "wind-in-trees", "wind", "pink-noise"], volumes: ["rain-on-window": v(45), "campfire": v(35), "wind-in-trees": v(25), "wind": v(15), "pink-noise": v(10)]),
            Mix(id: "night-river", name: "Night River", iconName: "moon.fill", soundIds: ["river", "crickets", "wind", "wind-in-trees", "pink-noise"], volumes: ["river": v(40), "crickets": v(40), "wind": v(20), "wind-in-trees": v(20), "pink-noise": v(10)]),
            Mix(id: "deep-night-forest", name: "Deep Night Forest", iconName: "sparkles", soundIds: ["wind-in-trees", "crickets", "pink-noise", "wind"], volumes: ["wind-in-trees": v(65), "crickets": v(50), "pink-noise": v(20), "wind": v(15)]),
            Mix(id: "storm-camp", name: "Storm Camp", iconName: "cloud.bolt.rain.fill", soundIds: ["heavy-rain", "campfire", "rain-on-window", "thunder", "wind-in-trees"], volumes: ["heavy-rain": v(55), "campfire": v(45), "rain-on-window": v(25), "thunder": v(20), "wind-in-trees": v(20)]),
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
            Mix(id: "heavy-storm", name: "Heavy Storm", iconName: "cloud.bolt.rain.fill", soundIds: ["heavy-rain", "rain-on-window", "thunder", "wind", "pink-noise"], volumes: ["heavy-rain": v(70), "rain-on-window": v(35), "thunder": v(35), "wind": v(25), "pink-noise": v(10)]),
            Mix(id: "forest-rain", name: "Forest Rain", iconName: "tree.fill", soundIds: ["light-rain", "wind-in-trees", "wind", "river", "pink-noise"], volumes: ["light-rain": v(55), "wind-in-trees": v(45), "wind": v(20), "river": v(15), "pink-noise": v(10)]),
            Mix(id: "rain-river", name: "Rain + River", iconName: "drop.fill", soundIds: ["light-rain", "river", "rain-on-window", "wind", "pink-noise"], volumes: ["light-rain": v(50), "river": v(50), "rain-on-window": v(35), "wind": v(15), "pink-noise": v(10)]),
            Mix(id: "spaced-thunder", name: "Spaced Thunder", iconName: "bolt.fill", soundIds: ["rain-on-window", "heavy-rain", "thunder", "wind", "pink-noise"], volumes: ["rain-on-window": v(55), "heavy-rain": v(50), "thunder": v(25), "wind": v(15), "pink-noise": v(10)]),
            Mix(id: "rainy-night", name: "Rainy Night", iconName: "moon.stars.fill", soundIds: ["rain-on-window", "heavy-rain", "crickets", "wind-in-trees", "pink-noise"], volumes: ["rain-on-window": v(60), "heavy-rain": v(55), "crickets": v(20), "wind-in-trees": v(15), "pink-noise": v(10)]),
            Mix(id: "storm-on-the-roof", name: "Storm on the Roof", iconName: "cloud.bolt.rain.fill", soundIds: ["rain-on-car-roof", "heavy-rain", "windshield-wipers", "thunder", "wind"], volumes: ["rain-on-car-roof": v(60), "heavy-rain": v(45), "windshield-wipers": v(35), "thunder": v(20), "wind": v(15)]),
            Mix(id: "tentstorm-shelter", name: "Tentstorm Shelter", iconName: "tent.fill", soundIds: ["rain-on-tent", "howling-wind", "heavy-rain", "thunder"], volumes: ["rain-on-tent": v(65), "howling-wind": v(30), "heavy-rain": v(25), "thunder": v(15)]),
            Mix(id: "cathedral-drizzle", name: "Cathedral Drizzle", iconName: "building.columns.fill", soundIds: ["church", "rain-on-window", "light-rain", "singing-bowl", "wind"], volumes: ["church": v(40), "rain-on-window": v(45), "light-rain": v(35), "singing-bowl": v(15), "wind": v(10)])
        ]
    )

    // MARK: - Focus & Study (8)
    static let focusStudy = MixCategory(
        id: "focus-study",
        title: "Focus & Study",
        iconName: "book.fill",
        mixes: [
            Mix(id: "productive-cafe", name: "Productive Cafe", iconName: "cup.and.saucer.fill", soundIds: ["cafe", "light-rain", "rain-on-window", "paper", "clock", "pink-noise"], volumes: ["cafe": v(45), "light-rain": v(25), "rain-on-window": v(25), "paper": v(15), "clock": v(10), "pink-noise": v(10)]),
            Mix(id: "library", name: "Library", iconName: "book.fill", soundIds: ["library", "paper", "clock", "pink-noise"], volumes: ["library": v(65), "paper": v(30), "clock": v(20), "pink-noise": v(15)]),
            Mix(id: "rainy-library", name: "Rainy Library", iconName: "books.vertical.fill", soundIds: ["library", "rain-on-window", "clock", "paper", "pink-noise"], volumes: ["library": v(55), "rain-on-window": v(35), "clock": v(15), "paper": v(15), "pink-noise": v(10)]),
            Mix(id: "focused-writing", name: "Focused Writing", iconName: "pencil.and.outline", soundIds: ["paper", "clock", "pink-noise", "library"], volumes: ["paper": v(55), "clock": v(25), "pink-noise": v(25), "library": v(20)]),
            Mix(id: "silent-reading", name: "Silent Reading", iconName: "text.book.closed.fill", soundIds: ["library", "paper", "pink-noise", "clock"], volumes: ["library": v(55), "paper": v(30), "pink-noise": v(20), "clock": v(10)]),
            Mix(id: "clock-pomodoro", name: "Clock Pomodoro", iconName: "timer", soundIds: ["pink-noise", "clock", "library", "paper"], volumes: ["pink-noise": v(45), "clock": v(35), "library": v(25), "paper": v(20)]),
            Mix(id: "cafe-by-the-sea", name: "Cafe by the Sea", iconName: "cup.and.saucer", soundIds: ["cafe", "waves", "seagulls", "rain-on-window", "pink-noise"], volumes: ["cafe": v(40), "waves": v(40), "seagulls": v(10), "rain-on-window": v(10), "pink-noise": v(10)]),
            Mix(id: "pink-rain-focus", name: "Pink Rain Focus", iconName: "waveform", soundIds: ["pink-noise", "rain-on-window", "light-rain", "clock", "paper"], volumes: ["pink-noise": v(55), "rain-on-window": v(35), "light-rain": v(25), "clock": v(10), "paper": v(10)]),
            Mix(id: "morse-focus-protocol", name: "Morse Focus Protocol", iconName: "dot.radiowaves.left.and.right", soundIds: ["morse-code", "typewriter", "paper", "clock", "library", "tuning-radio"], volumes: ["morse-code": v(25), "typewriter": v(30), "paper": v(30), "clock": v(20), "library": v(20), "tuning-radio": v(10)]),
            Mix(id: "office-late-hours", name: "Office Late Hours", iconName: "desktopcomputer", soundIds: ["office", "keyboard", "clock", "paper", "rain-on-window"], volumes: ["office": v(55), "keyboard": v(30), "clock": v(20), "paper": v(15), "rain-on-window": v(10)]),
            Mix(id: "projector-library-noir", name: "Projector Library Noir", iconName: "film.fill", soundIds: ["library", "slide-projector", "rain-on-window", "paper", "clock", "vinyl-effect"], volumes: ["library": v(45), "slide-projector": v(30), "rain-on-window": v(25), "paper": v(20), "clock": v(15), "vinyl-effect": v(10)])
        ]
    )

    // MARK: - Travel & Motion (8)
    static let travelMotion = MixCategory(
        id: "travel-motion",
        title: "Travel & Motion",
        iconName: "tram.fill",
        mixes: [
            Mix(id: "train-journey", name: "Train Journey", iconName: "tram.fill", soundIds: ["inside-a-train", "rain-on-window", "pink-noise", "wind"], volumes: ["inside-a-train": v(75), "rain-on-window": v(35), "pink-noise": v(15), "wind": v(10)]),
            Mix(id: "night-train", name: "Night Train", iconName: "moon.fill", soundIds: ["inside-a-train", "pink-noise", "rain-on-window", "wind"], volumes: ["inside-a-train": v(65), "pink-noise": v(35), "rain-on-window": v(20), "wind": v(10)]),
            Mix(id: "train-in-rain", name: "Train in Rain", iconName: "cloud.rain.fill", soundIds: ["inside-a-train", "rain-on-window", "light-rain", "pink-noise"], volumes: ["inside-a-train": v(70), "rain-on-window": v(40), "light-rain": v(35), "pink-noise": v(10)]),
            Mix(id: "train-storm", name: "Train + Storm", iconName: "cloud.bolt.rain.fill", soundIds: ["inside-a-train", "heavy-rain", "rain-on-window", "thunder", "pink-noise"], volumes: ["inside-a-train": v(65), "heavy-rain": v(45), "rain-on-window": v(35), "thunder": v(15), "pink-noise": v(10)]),
            Mix(id: "coastal-ride", name: "Coastal Ride", iconName: "water.waves", soundIds: ["inside-a-train", "waves", "seagulls", "wind", "rain-on-window"], volumes: ["inside-a-train": v(60), "waves": v(45), "seagulls": v(15), "wind": v(15), "rain-on-window": v(15)]),
            Mix(id: "quiet-carriage", name: "Quiet Carriage", iconName: "speaker.slash.fill", soundIds: ["inside-a-train", "pink-noise", "rain-on-window"], volumes: ["inside-a-train": v(55), "pink-noise": v(50), "rain-on-window": v(15)]),
            Mix(id: "cafe-commute", name: "Cafe Commute", iconName: "cup.and.saucer.fill", soundIds: ["inside-a-train", "cafe", "paper", "rain-on-window", "pink-noise"], volumes: ["inside-a-train": v(55), "cafe": v(35), "paper": v(20), "rain-on-window": v(15), "pink-noise": v(10)]),
            Mix(id: "night-station", name: "Night Station", iconName: "tram", soundIds: ["inside-a-train", "wind", "crickets", "rain-on-window", "pink-noise"], volumes: ["inside-a-train": v(55), "wind": v(25), "crickets": v(20), "rain-on-window": v(15), "pink-noise": v(10)]),
            Mix(id: "subway-umbrella-rush", name: "Subway Umbrella Rush", iconName: "tram.fill", soundIds: ["subway-station", "rain-on-umbrella", "busy-street", "traffic", "wind"], volumes: ["subway-station": v(55), "rain-on-umbrella": v(40), "busy-street": v(25), "traffic": v(20), "wind": v(10)]),
            Mix(id: "airport-night-shift", name: "Airport Night Shift", iconName: "airplane", soundIds: ["airport", "airplane", "rain-on-window", "clock", "traffic"], volumes: ["airport": v(55), "airplane": v(30), "rain-on-window": v(25), "clock": v(15), "traffic": v(10)]),
            Mix(id: "airplane-cruise", name: "Airplane Cruise", iconName: "airplane", soundIds: ["airplane", "airport", "pink-noise", "wind", "rain-on-window"], volumes: ["airplane": v(60), "airport": v(25), "pink-noise": v(30), "wind": v(15), "rain-on-window": v(10)]),
            Mix(id: "sailboat-lullaby", name: "Sailboat Lullaby", iconName: "sailboat.fill", soundIds: ["sailboat", "waves", "wind", "seagulls"], volumes: ["sailboat": v(55), "waves": v(40), "wind": v(20), "seagulls": v(10)]),
            Mix(id: "submarine-drift", name: "Submarine Drift", iconName: "water.waves", soundIds: ["submarine", "underwater", "bubbles", "whale", "waves"], volumes: ["submarine": v(45), "underwater": v(45), "bubbles": v(25), "whale": v(15), "waves": v(15)]),
            Mix(id: "rowing-at-dawn", name: "Rowing at Dawn", iconName: "sunrise", soundIds: ["rowing-boat", "river", "birds", "wind", "droplets"], volumes: ["rowing-boat": v(55), "river": v(40), "birds": v(20), "wind": v(15), "droplets": v(10)])
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
