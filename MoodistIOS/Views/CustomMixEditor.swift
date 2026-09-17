import SwiftUI
import MoodistKit

struct CustomMixEditor: View {
    @EnvironmentObject private var store: SoundStore
    @Environment(\.dismiss) private var dismiss
    var presetID: String? = nil
    @State private var name = ""
    @State private var icon = "sparkles"
    @State private var query = ""
    @State private var initialized = false
    private var valid: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (presetID != nil || store.hasSelection) }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L10n.presetNamePlaceholder, text: $name).accessibilityIdentifier("mix-name")
                    HStack {
                        SoundSymbol(name: icon).frame(width: 36, height: 36)
                        Text(name.isEmpty ? L10n.customMix : name)
                    }.padding(.vertical)
                }
                Section {
                    TextField(L10n.saveMixIconSearchPlaceholder, text: $query)
                }
                ForEach(PresetIcons.categories) { category in
                    let symbols = category.symbols.filter { query.isEmpty || $0.localizedStandardContains(query) }
                    if !symbols.isEmpty {
                        Section(L10n.saveMixIconCategoryTitle(category.id)) {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 48))]) {
                                ForEach(symbols, id: \.self) { symbol in
                                    Button { icon = symbol } label: {
                                        SoundSymbol(name: symbol).frame(width: 24, height: 24)
                                            .frame(width: 48, height: 48)
                                            .background(icon == symbol ? Color.accentColor.opacity(0.18) : Color.clear, in: .rect(cornerRadius: 12))
                                    }.buttonStyle(.plain)
                                        .accessibilityLabel(symbol.replacingOccurrences(of: ".", with: " "))
                                        .accessibilityAddTraits(icon == symbol ? .isSelected : [])
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(presetID == nil ? L10n.presetSaveDialogTitle : L10n.editMixTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L10n.cancel) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.save) {
                        if let id = presetID { store.updatePresetMetadata(id: id, name: name, iconName: icon) }
                        else { store.saveCurrentAsPreset(name: name, iconName: icon) }
                        dismiss()
                    }.disabled(!valid).accessibilityIdentifier("save-mix")
                }
            }
            .onAppear {
                guard !initialized else { return }; initialized = true
                if let id = presetID, let preset = store.presetsById[id] { name = preset.name; icon = preset.iconName }
            }
        }
    }
}
