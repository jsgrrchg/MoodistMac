import Foundation

public struct PresetIconCategory: Identifiable {
    public init(id: String, categorySymbol: String, symbols: [String]) {
        self.id = id; self.categorySymbol = categorySymbol; self.symbols = symbols
    }
    public let id: String
    public let categorySymbol: String
    public let symbols: [String]
}

public enum PresetIcons {
public static let categories: [PresetIconCategory] = [
    PresetIconCategory(
        id: "featured",
        categorySymbol: "sparkles",
        symbols: [
            "sparkles", "leaf.fill", "moon.zzz.fill", "cloud.rain.fill", "wind", "water.waves",
            "flame.fill", "music.note", "drop.fill", "snowflake", "sun.max.fill", "moon.stars.fill",
            "leaf.circle.fill", "bird.fill", "fish.fill", "pawprint.fill", "heart.fill",
            "star.fill",
            "book.fill", "cup.and.saucer.fill", "house.fill", "bolt.fill", "airplane", "car.fill",
            "headphones", "speaker.wave.2.fill",
        ]
    ),
    PresetIconCategory(
        id: "nature",
        categorySymbol: "leaf.fill",
        symbols: [
            "leaf.fill", "leaf.circle.fill", "tree.fill", "water.waves", "drop.fill", "flame.fill",
            "snowflake", "sun.max.fill", "sunrise.fill", "sunset.fill", "moon.stars.fill", "wind",
            "mountain.2.fill", "globe", "bird.fill", "fish.fill", "pawprint.fill", "flower.fill",
            "rainbow", "tornado",
        ]
    ),
    PresetIconCategory(
        id: "weather",
        categorySymbol: "cloud.sun.fill",
        symbols: [
            "cloud.sun.fill", "cloud.moon.fill", "cloud.fill", "cloud.rain.fill",
            "cloud.drizzle.fill",
            "cloud.heavyrain.fill", "cloud.bolt.fill", "cloud.bolt.rain.fill", "cloud.snow.fill",
            "cloud.fog.fill", "sun.max.fill", "moon.stars.fill", "wind", "tornado", "umbrella.fill",
            "drop.fill", "snowflake", "thermometer.sun.fill",
        ]
    ),
    PresetIconCategory(
        id: "sleep",
        categorySymbol: "moon.zzz.fill",
        symbols: [
            "moon.zzz.fill", "moon.fill", "moon.stars.fill", "bed.double.fill", "zzz", "alarm.fill",
            "clock.fill", "sparkles", "star.fill", "eye.slash.fill", "ear.fill", "heart.fill",
            "brain.head.profile", "waveform.path.ecg", "speaker.slash.fill", "cloud.moon.fill",
        ]
    ),
    PresetIconCategory(
        id: "focus",
        categorySymbol: "book.fill",
        symbols: [
            "book.fill", "books.vertical.fill", "doc.fill", "doc.text.fill", "folder.fill",
            "pencil.and.outline", "keyboard", "desktopcomputer", "printer.fill", "clock.fill",
            "chart.line.uptrend.xyaxis", "brain.head.profile", "lightbulb.fill", "glasses",
            "target",
            "checkmark.seal.fill", "graduationcap.fill", "briefcase.fill",
        ]
    ),
    PresetIconCategory(
        id: "places",
        categorySymbol: "house.fill",
        symbols: [
            "palm-tree-solid",
            "house.fill", "building.2.fill", "building.columns.fill", "tent.fill",
            "mappin.circle.fill",
            "map.fill", "tram.fill", "airplane", "car.fill", "bicycle", "sailboat.fill", "bus.fill",
            "ferry.fill", "train.side.front.car", "cup.and.saucer.fill", "cart.fill", "fork.knife",
            "washer.fill", "books.vertical.fill", "globe",
        ]
    ),
    PresetIconCategory(
        id: "audio",
        categorySymbol: "music.note",
        symbols: [
            "music.note", "music.note.list", "headphones", "speaker.wave.2.fill", "speaker.fill",
            "speaker.slash.fill", "waveform", "waveform.circle.fill",
            "dot.radiowaves.left.and.right",
            "radio.fill", "mic.fill", "guitars.fill", "pianokeys", "metronome.fill",
            "record.circle",
            "bell.fill",
        ]
    ),
    PresetIconCategory(
        id: "shapes",
        categorySymbol: "circle.grid.3x3.fill",
        symbols: [
            "circle.grid.3x3.fill", "circle.hexagongrid.fill", "square.grid.2x2.fill",
            "square.grid.3x3.fill",
            "triangle.fill", "diamond.fill", "hexagon.fill", "seal.fill", "capsule.fill",
            "scribble.variable", "paintbrush.fill", "wand.and.stars", "sparkles",
            "star.circle.fill",
            "circle.fill", "square.fill", "triangle.circle.fill", "scribble",
        ]
    ),
]

}
