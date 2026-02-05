//
//  L10n.swift
//  MoodistMac
//
//  Cadenas de UI (localizadas vía Localizable.strings).
//

import Foundation

private func tr(_ key: String, _ value: String) -> String {
    NSLocalizedString(key, tableName: nil, bundle: .main, value: value, comment: "")
}

enum L10n {
    private static let soundLabelById: [String: String] = {
        var dict: [String: String] = [:]
        for sound in SoundsData.categories.flatMap(\.sounds) {
            if dict[sound.id] == nil {
                dict[sound.id] = sound.label
            }
        }
        return dict
    }()

    private static let categoryTitleById: [String: String] = {
        var dict: [String: String] = [:]
        for category in SoundsData.categories {
            if dict[category.id] == nil {
                dict[category.id] = category.title
            }
        }
        return dict
    }()

    private static let mixNameById: [String: String] = {
        var dict: [String: String] = [:]
        for mix in MixesData.categories.flatMap(\.mixes) {
            if dict[mix.id] == nil {
                dict[mix.id] = mix.name
            }
        }
        return dict
    }()

    private static let mixCategoryTitleById: [String: String] = {
        var dict: [String: String] = [:]
        for category in MixesData.categories {
            if dict[category.id] == nil {
                dict[category.id] = category.title
            }
        }
        return dict
    }()
    // MARK: - General
    static var appName: String { tr("app_name", "Moodist") }
    static var options: String { tr("options", "Options") }
    static var close: String { tr("close", "Close") }

    // MARK: - Playback
    static var play: String { tr("play", "Play") }
    static var pause: String { tr("pause", "Pause") }
    static var shuffle: String { tr("shuffle", "Shuffle") }
    static var nextMix: String { tr("next_mix", "Next mix") }
    static var mediaKeyNextMix: String { tr("media_key_next_mix", "Use \"Next\" media key for next mix") }
    static var mediaKeyNextMixFooter: String { tr("media_key_next_mix_footer", "When enabled, the keyboard or headset \"Next track\" key loads a new random mix.") }
    static var unselectAll: String { tr("unselect_all", "Unselect all") }
    static var showInSounds: String { tr("show_in_sounds", "Show in Sounds") }
    static var showInMixes: String { tr("show_in_mixes", "Show in Mixes") }
    static var select: String { tr("select", "Play") }
    static var deselect: String { tr("deselect", "Deselect") }
    static var mute: String { tr("mute", "Mute") }
    static var unmute: String { tr("unmute", "Unmute") }
    static var stop: String { tr("stop", "Stop") }
    static var timer: String { tr("timer", "Timer") }
    static var timerMinutes: String { tr("timer_minutes", "Minutes") }
    static var timerHours: String { tr("timer_hours", "Hours") }
    static var timerStop: String { tr("timer_stop", "Stop") }
    static var timerCustom: String { tr("timer_custom", "Custom timer...") }
    static func timerRemaining(_ remaining: String) -> String {
        String(format: tr("timer_remaining", "Timer: %@ remaining"), remaining)
    }
    static var timerCustomTitle: String { tr("timer_custom_title", "Set timer") }
    static var timerCustomMessage: String { tr("timer_custom_message", "Enter the number of minutes for the timer.") }
    static var timerMinutesPlaceholder: String { tr("timer_minutes_placeholder", "Minutes") }
    static var timerStart: String { tr("timer_start", "Start") }
    static var timerFinishedTitle: String { tr("timer_finished_title", "Timer finished") }
    static func timerFinishedBody(_ name: String) -> String {
        String(format: tr("timer_finished_body", "“%@” has finished. Playback stopped."), name)
    }

    // MARK: - Sections
    static var sounds: String { tr("sounds", "Sounds") }
    static var mixes: String { tr("mixes", "Mixes") }
    static var globalVolume: String { tr("global_volume", "Global volume") }
    static var categories: String { tr("categories", "Categories") }
    static var currentlyPlaying: String { tr("currently_playing", "Currently playing") }
    static var noSoundsPlaying: String { tr("no_sounds_playing", "No sounds playing") }
    static var customMix: String { tr("custom_mix", "Custom mix") }
    static var controls: String { tr("controls", "Controls") }
    static var favorites: String { tr("favorites", "Favorites") }
    static var customMixesEmpty: String { tr("custom_mixes_empty", "No custom mixes yet") }
    static var addCustom: String { tr("add_custom", "Save mix") }
    static var clear: String { tr("clear", "Clear") }

    // MARK: - Favorites (accessibility)
    static var addToFavorites: String { tr("add_to_favorites", "Add to favorites") }
    static var removeFromFavorites: String { tr("remove_from_favorites", "Remove from favorites") }
    static func addToFavoritesLabel(_ name: String) -> String { String(format: tr("add_to_favorites_label", "Add %@ to favorites"), name) }
    static func removeFromFavoritesLabel(_ name: String) -> String { String(format: tr("remove_from_favorites_label", "Remove %@ from favorites"), name) }

    // MARK: - Updates
    static var checkForUpdates: String { tr("check_for_updates", "Check for Updates…") }
    static var updatesSection: String { tr("updates_section", "Updates") }
    static var updateAvailableTitle: String { tr("update_available_title", "New version available") }
    static func updateAvailableSubtitle(_ newVersion: String, _ currentVersion: String) -> String {
        String(format: tr("update_available_subtitle", "%@ is now available — you have %@."), newVersion, currentVersion)
    }
    static var updateReleaseNotesTitle: String { tr("update_release_notes", "What's new") }
    static var updateDownload: String { tr("update_download", "Download Update") }
    static var updateInstallAndRelaunch: String { tr("update_install_and_relaunch", "Install and Relaunch") }
    static var updateLater: String { tr("update_later", "Not Now") }
    static var updateSkip: String { tr("update_skip", "Skip This Version") }
    static var updateLearnMore: String { tr("update_learn_more", "Learn More") }
    static var updateCheckingTitle: String { tr("update_checking_title", "Checking for updates…") }
    static var updateDownloadingTitle: String { tr("update_downloading_title", "Downloading update…") }
    static var updatePreparingTitle: String { tr("update_preparing_title", "Preparing update…") }
    static var updateReadyTitle: String { tr("update_ready_title", "Ready to install") }
    static var updateInstallingTitle: String { tr("update_installing_title", "Installing update…") }
    static var updateCurrentVersion: String { tr("update_current_version", "Current") }
    static var updateNewVersion: String { tr("update_new_version", "New") }
    static var updateSize: String { tr("update_size", "Size") }
    static var updateCritical: String { tr("update_critical", "Critical") }
    static var updateNotesLoading: String { tr("update_notes_loading", "Loading release notes…") }
    static var updateNotesFailed: String { tr("update_notes_failed", "Could not load release notes.") }
    static var updatePreviewToggle: String { tr("update_preview_toggle", "Preview update window") }
    static var updatePreviewFooter: String { tr("update_preview_footer", "Temporary debug switch to test the new update UI.") }
    static var updatePermissionTitle: String { tr("update_permission_title", "Enable Automatic Updates?") }
    static func updatePermissionMessage(_ appName: String) -> String {
        String(format: tr("update_permission_message", "Allow %@ to check for updates automatically?"), appName)
    }
    static var updatePermissionEnable: String { tr("update_permission_enable", "Enable") }
    static var updatePermissionNotNow: String { tr("update_permission_not_now", "Not Now") }
    
    // MARK: - Options
    static var optionsTitle: String { tr("options_title", "Options") }
    static var playbackSection: String { tr("playback_section", "Playback") }
    static var appearanceSection: String { tr("appearance_section", "Appearance") }
    static var accentColor: String { tr("accent_color", "Accent color") }
    static var accentColorSystem: String { tr("accent_color_system", "Multicolor") }
    static var accentColorBlue: String { tr("accent_color_blue", "Blue") }
    static var accentColorPurple: String { tr("accent_color_purple", "Purple") }
    static var accentColorPink: String { tr("accent_color_pink", "Pink") }
    static var accentColorRed: String { tr("accent_color_red", "Red") }
    static var accentColorOrange: String { tr("accent_color_orange", "Orange") }
    static var accentColorYellow: String { tr("accent_color_yellow", "Yellow") }
    static var accentColorGreen: String { tr("accent_color_green", "Green") }
    static var accentColorGraphite: String { tr("accent_color_graphite", "Graphite") }
    static var appearanceMode: String { tr("appearance_mode", "Appearance") }
    static var appearanceAutomatic: String { tr("appearance_automatic", "Automatic") }
    static var appearanceLight: String { tr("appearance_light", "Light") }
    static var appearanceDark: String { tr("appearance_dark", "Dark") }
    static var textSize: String { tr("text_size", "Text size") }
    static var textSizeSmall: String { tr("text_size_small", "Small") }
    static var textSizeMedium: String { tr("text_size_medium", "Medium") }
    static var textSizeLarge: String { tr("text_size_large", "Large") }
    static var textSizeExtraLarge: String { tr("text_size_extra_large", "Extra large") }
    static var disableTransparencies: String { tr("disable_transparencies", "Disable transparencies") }
    static var disableTransparenciesFooter: String { tr("disable_transparencies_footer", "Turn this on to make the interface solid and reduce frosted effects.") }
    static var maxRecentMixes: String { tr("max_recent_mixes", "Recent mixes in sidebar") }
    static var maxRecentMixesFooter: String { tr("max_recent_mixes_footer", "Maximum number of recent mixes shown in the sidebar (10–15).") }
    static var maxRecentSounds: String { tr("max_recent_sounds", "Recent sounds in sidebar") }
    static var maxRecentSoundsFooter: String { tr("max_recent_sounds_footer", "Maximum number of recent sounds shown in the sidebar (10–15).") }
    static var dataSection: String { tr("data_section", "Data") }
    static var exportPreferences: String { tr("export_preferences", "Export preferences…") }
    static var exportPreferencesHint: String { tr("export_preferences_hint", "Save custom mixes, favorite mixes, and favorite sounds to a file") }
    static var exportFailed: String { tr("export_failed", "Export failed") }
    static var exportFailedMessage: String { tr("export_failed_message", "Could not write the file. Check the location and try again.") }
    static var importPreferences: String { tr("import_preferences", "Import preferences…") }
    static var importPreferencesHint: String { tr("import_preferences_hint", "Load custom mixes, favorite mixes, and favorite sounds from a file") }
    static var importFailed: String { tr("import_failed", "Import failed") }
    static var importFailedMessage: String { tr("import_failed_message", "Could not read the file or the file format is invalid.") }
    static var aboutSection: String { tr("about_section", "About") }
    static var version: String { tr("version", "Version") }
    static var resetSelectionAndFavorites: String { tr("reset_selection", "Reset selection and favorites") }
    static var restoreAllDefaults: String { tr("restore_defaults", "Restore all to defaults") }
    static var visitWeb: String { tr("visit_web", "Visit Moodist on the web") }
    static var sourceCode: String { tr("source_code", "Source code (GitHub)") }
    static var resetConfirmTitle: String { tr("reset_confirm_title", "Reset selection?") }
    static var resetConfirmMessage: String { tr("reset_confirm_message", "All selected sounds and favorites will be cleared. Global volume will not change.") }
    static var restoreConfirmTitle: String { tr("restore_confirm_title", "Restore defaults?") }
    static var restoreConfirmMessage: String { tr("restore_confirm_message", "Selection, favorites and global volume will be reset. Playback will stop.") }
    static var cancel: String { tr("cancel", "Cancel") }
    static var reset: String { tr("reset", "Reset") }
    static var restore: String { tr("restore", "Restore") }
    static var menuBar: String { tr("menu_bar", "Menu bar") }
    static var menuBarShow: String { tr("menu_bar_show", "Show in menu bar") }
    static var menuBarShowFooter: String { tr("menu_bar_show_footer", "Show an icon in the macOS menu bar for quick access.") }
    static var openWindow: String { tr("open_window", "Open Moodist") }
    static var floatingPlayer: String { tr("floating_player", "Floating player") }
    static var showFloatingPlayer: String { tr("show_floating_player", "Show floating player") }
    static var quit: String { tr("quit", "Quit Moodist") }

    // MARK: - Sidebar
    static var sidebarFavorites: String { tr("sidebar_favorites", "Favorite Sounds") }
    static var sidebarPresets: String { tr("sidebar_presets", "Presets") }
    static var sidebarFavoriteMixes: String { tr("sidebar_favorite_mixes", "Favorite Mixes") }
    static var sidebarFavoriteMixesEmpty: String { tr("sidebar_favorite_mixes_empty", "No favorite mixes") }
    static var sidebarRecentSounds: String { tr("sidebar_recent_sounds", "Recent Sounds") }
    static var sidebarRecentSoundsEmpty: String { tr("sidebar_recent_sounds_empty", "No recent sounds") }
    static var sidebarRecentMixes: String { tr("sidebar_recent_mixes", "Recent Mixes") }
    static var sidebarRecentMixesEmpty: String { tr("sidebar_recent_mixes_empty", "No recent mixes") }
    static var sidebarFavoritesEmpty: String { tr("sidebar_favorites_empty", "No favorites yet") }
    static var sidebarPresetsEmpty: String { tr("sidebar_presets_empty", "No presets yet") }
    static var presetSaveCurrent: String { tr("preset_save_current", "Save as mix") }
    static var presetApply: String { tr("preset_apply", "Play Mix") }
    static var presetDelete: String { tr("preset_delete", "Delete mix") }
    static var presetSaveDialogTitle: String { tr("preset_save_dialog_title", "Save Mix") }
    static var presetNamePlaceholder: String { tr("preset_name_placeholder", "Mix name") }
    static var presetSaved: String { tr("preset_saved", "Mix saved") }
    static var saveMixSubtitle: String { tr("save_mix_subtitle", "Give your mix a name and pick an icon.") }
    static func saveMixIconLabel(_ iconName: String) -> String {
        String(format: tr("save_mix_icon_label_format", "Icon: %@"), iconName)
    }
    static var saveMixIconMenuHint: String { tr("save_mix_icon_menu_hint", "Opens menu to choose an icon for the mix") }
    static var iconLabel: String { tr("icon_label", "Icon") }
    static var addToMix: String { tr("add_to_mix", "Add to mix") }
    static var createNewMix: String { tr("create_new_mix", "Create new mix…") }
    static var save: String { tr("save", "Save") }

    // MARK: - Search
    static var search: String { tr("search", "Search") }
    static var searchPlaceholder: String { tr("search_placeholder", "Search sounds…") }
    
    // MARK: - Language
    static var language: String { tr("language", "Language") }
    static var languageSystem: String { tr("language_system", "System") }
    static var languageEnglish: String { tr("language_english", "English") }
    static var languageSpanish: String { tr("language_spanish", "Spanish") }
    static var languageFooter: String { tr("language_footer", "Choose the app language. System uses your macOS language preference.") }
    
    // MARK: - Dynamic content by id
    static func soundLabel(_ soundId: String) -> String {
        let key = "sound_\(soundId)"
        let fallback = soundLabelById[soundId] ?? soundId
        return tr(key, fallback)
    }
    
    static func categoryTitle(_ categoryId: String) -> String {
        let key = "category_\(categoryId)"
        let fallback = categoryTitleById[categoryId] ?? categoryId
        return tr(key, fallback)
    }
    
    static func mixName(_ mixId: String) -> String {
        let key = "mix_\(mixId)"
        let fallback = mixNameById[mixId] ?? mixId
        return tr(key, fallback)
    }
    
    static func mixCategoryTitle(_ mixCategoryId: String) -> String {
        let key = "mixcat_\(mixCategoryId)"
        let fallback = mixCategoryTitleById[mixCategoryId] ?? mixCategoryId
        return tr(key, fallback)
    }
    
    // MARK: - State and accessibility
    static var stateExpanded: String { tr("state_expanded", "expanded") }
    static var stateCollapsed: String { tr("state_collapsed", "collapsed") }
    static var stateSelected: String { tr("state_selected", "selected") }
    static var stateNotSelected: String { tr("state_not_selected", "not selected") }
    static func volumeForLabel(_ label: String) -> String { String(format: tr("volume_for_label", "Volume for %@"), label) }
    static func countSounds(_ count: Int) -> String { String(format: tr("count_sounds", "%d sounds"), count) }
    static func soundsWillBeSaved(_ count: Int) -> String { String(format: tr("sounds_will_be_saved", "%d sounds will be saved."), count) }
    
    // MARK: - Options additional strings
    static var dataSectionFooter: String { tr("data_section_footer", "Reset only clears selection and favorites. Restore also resets global volume.") }
    static var resetSelectionHint: String { tr("reset_selection_hint", "Clears selection and favorites") }
    static var restoreDefaultsHint: String { tr("restore_defaults_hint", "Resets all settings to defaults") }
    
    // MARK: - Accessibility
    static var section: String { tr("section", "Section") }
    static var resizeSidebar: String { tr("resize_sidebar", "Resize sidebar") }
    static var resizeSidebarHint: String { tr("resize_sidebar_hint", "Drag to resize sidebar width") }
    static var expandSection: String { tr("expand_section", "Expand section") }
    static var collapseSection: String { tr("collapse_section", "Collapse section") }
    static var collapseAllCategories: String { tr("collapse_all_categories", "Collapse all") }
    static var expandAllCategories: String { tr("expand_all_categories", "Expand all") }
    static func categoryExpandHint(_ isExpanded: Bool) -> String {
        isExpanded ? tr("category_collapse_hint", "Double tap to collapse category") : tr("category_expand_hint", "Double tap to expand category")
    }
    static var clickToggleSelection: String { tr("click_toggle_selection", "Click to toggle selection") }
    static var clickApplyMix: String { tr("click_apply_mix", "Click to play mix") }
    static var clickApplyPreset: String { tr("click_apply_preset", "Click to apply preset") }
    static var doubleTapPlayMix: String { tr("double_tap_play_mix", "Double tap to play this mix") }
}
