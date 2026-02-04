//
//  SoundsData.swift
//  MoodistMac
//
//  Categorías y sonidos (equivalente a src/data/sounds).
//

import Foundation

enum SoundsData {
    static let categories: [SoundCategory] = [
        nature,
        rain,
        animals,
        urban,
        places,
        transport,
        things,
        noise,
        binaural
    ]

    /// Diccionario estático para búsquedas O(1) de sonidos por ID (evita duplicar en vistas).
    static let allSoundsById: [String: Sound] = Dictionary(uniqueKeysWithValues: categories.flatMap(\.sounds).map { ($0.id, $0) })

    // MARK: - Nature
    static let nature = SoundCategory(
        id: "nature",
        title: "Nature",
        iconName: SoundIcons.leafFill,
        sounds: [
            Sound(id: "river", label: "River", fileName: "river.mp3", categoryFolder: "nature", iconName: SoundIcons.waterWaves),
            Sound(id: "waves", label: "Waves", fileName: "waves.mp3", categoryFolder: "nature", iconName: SoundIcons.waterWaves),
            Sound(id: "campfire", label: "Campfire", fileName: "campfire.mp3", categoryFolder: "nature", iconName: SoundIcons.flameFill),
            Sound(id: "wind", label: "Wind", fileName: "wind.mp3", categoryFolder: "nature", iconName: SoundIcons.wind),
            Sound(id: "howling-wind", label: "Howling Wind", fileName: "howling-wind.mp3", categoryFolder: "nature", iconName: SoundIcons.wind),
            Sound(id: "wind-in-trees", label: "Wind in Trees", fileName: "wind-in-trees.mp3", categoryFolder: "nature", iconName: SoundIcons.leafFill),
            Sound(id: "waterfall", label: "Waterfall", fileName: "waterfall.mp3", categoryFolder: "nature", iconName: SoundIcons.waterWaves),
            Sound(id: "walk-in-snow", label: "Walk in Snow", fileName: "walk-in-snow.mp3", categoryFolder: "nature", iconName: SoundIcons.snowflake),
            Sound(id: "walk-on-leaves", label: "Walk on Leaves", fileName: "walk-on-leaves.mp3", categoryFolder: "nature", iconName: SoundIcons.leafFill),
            Sound(id: "walk-on-gravel", label: "Walk on Gravel", fileName: "walk-on-gravel.mp3", categoryFolder: "nature", iconName: SoundIcons.gridFill),
            Sound(id: "droplets", label: "Droplets", fileName: "droplets.mp3", categoryFolder: "nature", iconName: SoundIcons.dropFill),
            Sound(id: "jungle", label: "Jungle", fileName: "jungle.mp3", categoryFolder: "nature", iconName: SoundIcons.treeFill)
        ]
    )

    // MARK: - Rain
    static let rain = SoundCategory(
        id: "rain",
        title: "Rain",
        iconName: SoundIcons.cloudRainFill,
        sounds: [
            Sound(id: "light-rain", label: "Light Rain", fileName: "light-rain.mp3", categoryFolder: "rain", iconName: SoundIcons.cloudDrizzleFill),
            Sound(id: "heavy-rain", label: "Heavy Rain", fileName: "heavy-rain.mp3", categoryFolder: "rain", iconName: SoundIcons.cloudHeavyrainFill),
            Sound(id: "thunder", label: "Thunder", fileName: "thunder.mp3", categoryFolder: "rain", iconName: SoundIcons.cloudBoltFill),
            Sound(id: "rain-on-window", label: "Rain on Window", fileName: "rain-on-window.mp3", categoryFolder: "rain", iconName: SoundIcons.rectangle),
            Sound(id: "rain-on-car-roof", label: "Rain on Car Roof", fileName: "rain-on-car-roof.mp3", categoryFolder: "rain", iconName: SoundIcons.carFill),
            Sound(id: "rain-on-umbrella", label: "Rain on Umbrella", fileName: "rain-on-umbrella.mp3", categoryFolder: "rain", iconName: SoundIcons.umbrellaFill),
            Sound(id: "rain-on-tent", label: "Rain on Tent", fileName: "rain-on-tent.mp3", categoryFolder: "rain", iconName: SoundIcons.tentFill),
            Sound(id: "rain-on-leaves", label: "Rain on Leaves", fileName: "rain-on-leaves.mp3", categoryFolder: "rain", iconName: SoundIcons.dropFill)
        ]
    )

    // MARK: - Animals
    static let animals = SoundCategory(
        id: "animals",
        title: "Animals",
        iconName: SoundIcons.pawprintFill,
        sounds: [
            Sound(id: "birds", label: "Birds", fileName: "birds.mp3", categoryFolder: "animals", iconName: SoundIcons.birdFill),
            Sound(id: "seagulls", label: "Seagulls", fileName: "seagulls.mp3", categoryFolder: "animals", iconName: SoundIcons.birdFill),
            Sound(id: "crickets", label: "Crickets", fileName: "crickets.mp3", categoryFolder: "animals", iconName: SoundIcons.leafFill),
            Sound(id: "wolf", label: "Wolf", fileName: "wolf.mp3", categoryFolder: "animals", iconName: SoundIcons.pawprintFill),
            Sound(id: "owl", label: "Owl", fileName: "owl.mp3", categoryFolder: "animals", iconName: SoundIcons.birdFill),
            Sound(id: "frog", label: "Frog", fileName: "frog.mp3", categoryFolder: "animals", iconName: SoundIcons.lizardFill),
            Sound(id: "dog-barking", label: "Dog Barking", fileName: "dog-barking.mp3", categoryFolder: "animals", iconName: SoundIcons.dogFill),
            Sound(id: "horse-gallop", label: "Horse Gallop", fileName: "horse-gallop.mp3", categoryFolder: "animals", iconName: SoundIcons.hareFill),
            Sound(id: "cat-purring", label: "Cat Purring", fileName: "cat-purring.mp3", categoryFolder: "animals", iconName: SoundIcons.catFill),
            Sound(id: "crows", label: "Crows", fileName: "crows.mp3", categoryFolder: "animals", iconName: SoundIcons.birdFill),
            Sound(id: "whale", label: "Whale", fileName: "whale.mp3", categoryFolder: "animals", iconName: SoundIcons.fishFill),
            Sound(id: "beehive", label: "Beehive", fileName: "beehive.mp3", categoryFolder: "animals", iconName: SoundIcons.ladybugFill),
            Sound(id: "woodpecker", label: "Woodpecker", fileName: "woodpecker.mp3", categoryFolder: "animals", iconName: SoundIcons.birdFill),
            Sound(id: "chickens", label: "Chickens", fileName: "chickens.mp3", categoryFolder: "animals", iconName: SoundIcons.birdFill),
            Sound(id: "cows", label: "Cows", fileName: "cows.mp3", categoryFolder: "animals", iconName: SoundIcons.hareFill),
            Sound(id: "sheep", label: "Sheep", fileName: "sheep.mp3", categoryFolder: "animals", iconName: SoundIcons.hareFill)
        ]
    )

    // MARK: - Urban
    static let urban = SoundCategory(
        id: "urban",
        title: "Urban",
        iconName: SoundIcons.building2Fill,
        sounds: [
            Sound(id: "highway", label: "Highway", fileName: "highway.mp3", categoryFolder: "urban", iconName: SoundIcons.carFill),
            Sound(id: "road", label: "Road", fileName: "road.mp3", categoryFolder: "urban", iconName: SoundIcons.roadLanes),
            Sound(id: "ambulance-siren", label: "Ambulance Siren", fileName: "ambulance-siren.mp3", categoryFolder: "urban", iconName: SoundIcons.crossCaseFill),
            Sound(id: "busy-street", label: "Busy Street", fileName: "busy-street.mp3", categoryFolder: "urban", iconName: SoundIcons.person2Fill),
            Sound(id: "crowd", label: "Crowd", fileName: "crowd.mp3", categoryFolder: "urban", iconName: SoundIcons.person3Fill),
            Sound(id: "traffic", label: "Traffic", fileName: "traffic.mp3", categoryFolder: "urban", iconName: SoundIcons.carFill),
            Sound(id: "fireworks", label: "Fireworks", fileName: "fireworks.mp3", categoryFolder: "urban", iconName: SoundIcons.sparkles)
        ]
    )

    // MARK: - Places
    static let places = SoundCategory(
        id: "places",
        title: "Places",
        iconName: SoundIcons.mappinCircleFill,
        sounds: [
            Sound(id: "cafe", label: "Cafe", fileName: "cafe.mp3", categoryFolder: "places", iconName: SoundIcons.cupSaucerFill),
            Sound(id: "airport", label: "Airport", fileName: "airport.mp3", categoryFolder: "places", iconName: SoundIcons.airplane),
            Sound(id: "church", label: "Church", fileName: "church.mp3", categoryFolder: "places", iconName: SoundIcons.buildingColumnsFill),
            Sound(id: "temple", label: "Temple", fileName: "temple.mp3", categoryFolder: "places", iconName: SoundIcons.buildingFill),
            Sound(id: "construction-site", label: "Construction Site", fileName: "construction-site.mp3", categoryFolder: "places", iconName: SoundIcons.hammerFill),
            Sound(id: "underwater", label: "Underwater", fileName: "underwater.mp3", categoryFolder: "places", iconName: SoundIcons.waterWaves),
            Sound(id: "crowded-bar", label: "Crowded Bar", fileName: "crowded-bar.mp3", categoryFolder: "places", iconName: SoundIcons.wineglassFill),
            Sound(id: "night-village", label: "Night Village", fileName: "night-village.mp3", categoryFolder: "places", iconName: SoundIcons.moonStarsFill),
            Sound(id: "subway-station", label: "Subway Station", fileName: "subway-station.mp3", categoryFolder: "places", iconName: SoundIcons.tramFill),
            Sound(id: "office", label: "Office", fileName: "office.mp3", categoryFolder: "places", iconName: SoundIcons.building2Fill),
            Sound(id: "supermarket", label: "Supermarket", fileName: "supermarket.mp3", categoryFolder: "places", iconName: SoundIcons.cartFill),
            Sound(id: "carousel", label: "Carousel", fileName: "carousel.mp3", categoryFolder: "places", iconName: SoundIcons.circleHexagonGridFill),
            Sound(id: "laboratory", label: "Laboratory", fileName: "laboratory.mp3", categoryFolder: "places", iconName: SoundIcons.flaskFill),
            Sound(id: "laundry-room", label: "Laundry Room", fileName: "laundry-room.mp3", categoryFolder: "places", iconName: SoundIcons.washerFill),
            Sound(id: "restaurant", label: "Restaurant", fileName: "restaurant.mp3", categoryFolder: "places", iconName: SoundIcons.forkKnife),
            Sound(id: "library", label: "Library", fileName: "library.mp3", categoryFolder: "places", iconName: SoundIcons.booksVerticalFill)
        ]
    )

    // MARK: - Transport
    static let transport = SoundCategory(
        id: "transport",
        title: "Transport",
        iconName: SoundIcons.carFill,
        sounds: [
            Sound(id: "train", label: "Train", fileName: "train.mp3", categoryFolder: "transport", iconName: SoundIcons.tramFill),
            Sound(id: "inside-a-train", label: "Inside a Train", fileName: "inside-a-train.mp3", categoryFolder: "transport", iconName: SoundIcons.tramFill),
            Sound(id: "airplane", label: "Airplane", fileName: "airplane.mp3", categoryFolder: "transport", iconName: SoundIcons.airplane),
            Sound(id: "submarine", label: "Submarine", fileName: "submarine.mp3", categoryFolder: "transport", iconName: SoundIcons.waterWaves),
            Sound(id: "sailboat", label: "Sailboat", fileName: "sailboat.mp3", categoryFolder: "transport", iconName: SoundIcons.sailboatFill),
            Sound(id: "rowing-boat", label: "Rowing Boat", fileName: "rowing-boat.mp3", categoryFolder: "transport", iconName: SoundIcons.sailboatFill)
        ]
    )

    // MARK: - Things
    static let things = SoundCategory(
        id: "things",
        title: "Things",
        iconName: SoundIcons.cubeFill,
        sounds: [
            Sound(id: "keyboard", label: "Keyboard", fileName: "keyboard.mp3", categoryFolder: "things", iconName: SoundIcons.keyboard),
            Sound(id: "typewriter", label: "Typewriter", fileName: "typewriter.mp3", categoryFolder: "things", iconName: SoundIcons.keyboard),
            Sound(id: "paper", label: "Paper", fileName: "paper.mp3", categoryFolder: "things", iconName: SoundIcons.docFill),
            Sound(id: "clock", label: "Clock", fileName: "clock.mp3", categoryFolder: "things", iconName: SoundIcons.clockFill),
            Sound(id: "wind-chimes", label: "Wind Chimes", fileName: "wind-chimes.mp3", categoryFolder: "things", iconName: SoundIcons.musicNote),
            Sound(id: "singing-bowl", label: "Singing Bowl", fileName: "singing-bowl.mp3", categoryFolder: "things", iconName: SoundIcons.circleFill),
            Sound(id: "ceiling-fan", label: "Ceiling Fan", fileName: "ceiling-fan.mp3", categoryFolder: "things", iconName: SoundIcons.fanbladesFill),
            Sound(id: "dryer", label: "Dryer", fileName: "dryer.mp3", categoryFolder: "things", iconName: SoundIcons.dryerFill),
            Sound(id: "slide-projector", label: "Slide Projector", fileName: "slide-projector.mp3", categoryFolder: "things", iconName: SoundIcons.filmFill),
            Sound(id: "boiling-water", label: "Boiling Water", fileName: "boiling-water.mp3", categoryFolder: "things", iconName: SoundIcons.dropFill),
            Sound(id: "bubbles", label: "Bubbles", fileName: "bubbles.mp3", categoryFolder: "things", iconName: SoundIcons.bubbleFill),
            Sound(id: "tuning-radio", label: "Tuning Radio", fileName: "tuning-radio.mp3", categoryFolder: "things", iconName: SoundIcons.radioFill),
            Sound(id: "morse-code", label: "Morse Code", fileName: "morse-code.mp3", categoryFolder: "things", iconName: SoundIcons.dotRadiowaves),
            Sound(id: "washing-machine", label: "Washing Machine", fileName: "washing-machine.mp3", categoryFolder: "things", iconName: SoundIcons.washerFill),
            Sound(id: "vinyl-effect", label: "Vinyl Effect", fileName: "vinyl-effect.mp3", categoryFolder: "things", iconName: SoundIcons.recordCircle),
            Sound(id: "windshield-wipers", label: "Windshield Wipers", fileName: "windshield-wipers.mp3", categoryFolder: "things", iconName: SoundIcons.carFill)
        ]
    )

    // MARK: - Noise
    static let noise = SoundCategory(
        id: "noise",
        title: "Noise",
        iconName: SoundIcons.waveform,
        sounds: [
            Sound(id: "white-noise", label: "White Noise", fileName: "white-noise.wav", categoryFolder: "noise", iconName: SoundIcons.waveform),
            Sound(id: "pink-noise", label: "Pink Noise", fileName: "pink-noise.wav", categoryFolder: "noise", iconName: SoundIcons.waveform),
            Sound(id: "brown-noise", label: "Brown Noise", fileName: "brown-noise.wav", categoryFolder: "noise", iconName: SoundIcons.waveform)
        ]
    )

    // MARK: - Binaural (waveform.circle para diferenciar de noise)
    static let binaural = SoundCategory(
        id: "binaural",
        title: "Binaural",
        iconName: SoundIcons.waveformCircleFill,
        sounds: [
            Sound(id: "binaural-alpha", label: "Alpha", fileName: "binaural-alpha.wav", categoryFolder: "binaural", iconName: SoundIcons.waveformCircleFill),
            Sound(id: "binaural-beta", label: "Beta", fileName: "binaural-beta.wav", categoryFolder: "binaural", iconName: SoundIcons.waveformCircleFill),
            Sound(id: "binaural-delta", label: "Delta", fileName: "binaural-delta.wav", categoryFolder: "binaural", iconName: SoundIcons.waveformCircleFill),
            Sound(id: "binaural-gamma", label: "Gamma", fileName: "binaural-gamma.wav", categoryFolder: "binaural", iconName: SoundIcons.waveformCircleFill),
            Sound(id: "binaural-theta", label: "Theta", fileName: "binaural-theta.wav", categoryFolder: "binaural", iconName: SoundIcons.waveformCircleFill)
        ]
    )
}
