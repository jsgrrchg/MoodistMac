//
//  L10n.swift
//  MoodistMac
//
//  UI strings localized through Localizable.strings.
//

import Foundation

private func tr(_ key: String, _ value: String) -> String {
    MoodistResources.localizedString(key, fallback: value)
}

public enum L10n {
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

    private static let saveMixIconCategoryTitleById: [String: String] = [
        "featured": "Featured",
        "nature": "Nature",
        "weather": "Weather",
        "sleep": "Sleep",
        "focus": "Focus",
        "places": "Places",
        "audio": "Audio",
        "shapes": "Shapes",
    ]
    // MARK: - General
    public static var appName: String { tr("app_name", "Moodist") }
    public static var options: String { tr("options", "Options") }
    public static var close: String { tr("close", "Close") }
    public static func aboutApp(_ appName: String) -> String {
        String(format: tr("about_app_format", "About %@"), appName)
    }

    // MARK: - Playback
    public static var play: String { tr("play", "Play") }
    public static var pause: String { tr("pause", "Pause") }
    public static var playbackMenu: String { tr("playback_menu", "Playback") }
    public static var shuffle: String { tr("shuffle", "Shuffle") }
    public static var nextMix: String { tr("next_mix", "Next mix") }
    public static var automixLabel: String { tr("automix_label", "Pomodoro") }
    public static var automixRotate: String { tr("automix_rotate", "Rotate") }
    public static var automixAllMixes: String { tr("automix_all_mixes", "All Mixes") }
    public static var automixOnlyCustom: String { tr("automix_only_custom", "Only Custom") }
    public static var automixHelpIdle: String { tr("automix_help_idle", "Pomodoro – auto mix") }
    public static func automixHelpActive(_ interval: String) -> String {
        String(format: tr("automix_help_active_format", "Pomodoro – %@"), interval)
    }
    public static var mediaKeyNextMix: String {
        tr("media_key_next_mix", "Use \"Next\" media key for next mix")
    }
    public static var mediaKeyNextMixFooter: String {
        tr(
            "media_key_next_mix_footer",
            "When enabled, the keyboard or headset \"Next track\" key loads a new random mix.")
    }
    public static var unselectAll: String { tr("unselect_all", "Unselect all") }
    public static var select: String { tr("select", "Play") }
    public static var deselect: String { tr("deselect", "Deselect") }
    public static var mute: String { tr("mute", "Mute") }
    public static var unmute: String { tr("unmute", "Unmute") }
    public static var stop: String { tr("stop", "Stop") }
    public static var timer: String { tr("timer", "Timer") }
    public static var timerMinutes: String { tr("timer_minutes", "Minutes") }
    public static var timerHours: String { tr("timer_hours", "Hours") }
    public static var timerStop: String { tr("timer_stop", "Stop") }
    public static var timerCustom: String { tr("timer_custom", "Custom timer...") }
    public static func timerRemaining(_ remaining: String) -> String {
        String(format: tr("timer_remaining", "Timer: %@ remaining"), remaining)
    }
    public static var timerCustomTitle: String { tr("timer_custom_title", "Set timer") }
    public static var timerCustomMessage: String {
        tr("timer_custom_message", "Enter the number of minutes for the timer.")
    }
    public static var timerQuickPresets: String { tr("timer_quick_presets", "Quick presets") }
    public static var timerReplace: String { tr("timer_replace", "Replace timer") }
    public static var timerStopCurrent: String { tr("timer_stop_current", "Stop current") }
    public static func timerActiveNow(_ remaining: String) -> String {
        String(format: tr("timer_active_now", "Current timer: %@ remaining"), remaining)
    }
    public static var timerStart: String { tr("timer_start", "Start") }
    public static var timerFinishedTitle: String { tr("timer_finished_title", "Timer finished") }
    public static func timerFinishedBody(_ name: String) -> String {
        String(format: tr("timer_finished_body", "“%@” has finished. Playback stopped."), name)
    }

    // MARK: - Sections
    public static var sounds: String { tr("sounds", "Sounds") }
    public static var mixes: String { tr("mixes", "Mixes") }
    public static var globalVolume: String { tr("global_volume", "Global volume") }
    public static var categories: String { tr("categories", "Categories") }
    public static var currentlyPlaying: String { tr("currently_playing", "Currently playing") }
    public static var noSoundsPlaying: String { tr("no_sounds_playing", "No sounds playing") }
    public static var customMix: String { tr("custom_mix", "Custom mix") }
    public static var controls: String { tr("controls", "Controls") }
    public static var favorites: String { tr("favorites", "Favorites") }
    public static var customMixesEmpty: String { tr("custom_mixes_empty", "No custom mixes yet") }
    public static var addCustom: String { tr("add_custom", "Save mix") }
    public static var clear: String { tr("clear", "Clear") }

    // MARK: - Favorites (accessibility)
    public static func addToFavoritesLabel(_ name: String) -> String {
        String(format: tr("add_to_favorites_label", "Add %@ to favorites"), name)
    }
    public static func removeFromFavoritesLabel(_ name: String) -> String {
        String(format: tr("remove_from_favorites_label", "Remove %@ from favorites"), name)
    }

    // MARK: - Updates
    public static var checkForUpdates: String { tr("check_for_updates", "Check for Updates…") }
    public static var updatesSection: String { tr("updates_section", "Updates") }
    public static var updateAvailableTitle: String {
        tr("update_available_title", "New version available")
    }
    public static func updateAvailableSubtitle(_ newVersion: String, _ currentVersion: String) -> String {
        String(
            format: tr("update_available_subtitle", "%@ is now available — you have %@."),
            newVersion, currentVersion)
    }
    public static var updateReleaseNotesTitle: String { tr("update_release_notes", "What's new") }
    public static var updateDownload: String { tr("update_download", "Download Update") }
    public static var updateInstallAndRelaunch: String {
        tr("update_install_and_relaunch", "Install and Relaunch")
    }
    public static var updateLater: String { tr("update_later", "Not Now") }
    public static var updateSkip: String { tr("update_skip", "Skip This Version") }
    public static var updateLearnMore: String { tr("update_learn_more", "Learn More") }
    public static var updateCheckingTitle: String { tr("update_checking_title", "Checking for updates…") }
    public static var updateDownloadingTitle: String {
        tr("update_downloading_title", "Downloading update…")
    }
    public static var updatePreparingTitle: String { tr("update_preparing_title", "Preparing update…") }
    public static var updateReadyTitle: String { tr("update_ready_title", "Ready to install") }
    public static var updateInstallingTitle: String { tr("update_installing_title", "Installing update…") }
    public static var updateCurrentVersion: String { tr("update_current_version", "Current") }
    public static var updateNewVersion: String { tr("update_new_version", "New") }
    public static var updateSize: String { tr("update_size", "Size") }
    public static var updateCritical: String { tr("update_critical", "Critical") }
    public static var updateNotesLoading: String { tr("update_notes_loading", "Loading release notes…") }
    public static var updateNotesFailed: String {
        tr("update_notes_failed", "Could not load release notes.")
    }
    public static var updatePermissionTitle: String {
        tr("update_permission_title", "Enable Automatic Updates?")
    }
    public static func updatePermissionMessage(_ appName: String) -> String {
        String(
            format: tr("update_permission_message", "Allow %@ to check for updates automatically?"),
            appName)
    }
    public static var updatePermissionEnable: String { tr("update_permission_enable", "Enable") }
    public static var updatePermissionNotNow: String { tr("update_permission_not_now", "Not Now") }

    // MARK: - Options
    public static var optionsTitle: String { tr("options_title", "Options") }
    public static var playbackSection: String { tr("playback_section", "Playback") }
    public static var appearanceSection: String { tr("appearance_section", "Appearance") }
    public static var accentColor: String { tr("accent_color", "Accent color") }
    public static var accentColorSystem: String { tr("accent_color_system", "Multicolor") }
    public static var accentColorBlue: String { tr("accent_color_blue", "Blue") }
    public static var accentColorPurple: String { tr("accent_color_purple", "Purple") }
    public static var accentColorPink: String { tr("accent_color_pink", "Pink") }
    public static var accentColorRed: String { tr("accent_color_red", "Red") }
    public static var accentColorOrange: String { tr("accent_color_orange", "Orange") }
    public static var accentColorYellow: String { tr("accent_color_yellow", "Yellow") }
    public static var accentColorGreen: String { tr("accent_color_green", "Green") }
    public static var accentColorGraphite: String { tr("accent_color_graphite", "Graphite") }
    public static var appearanceMode: String { tr("appearance_mode", "Appearance") }
    public static var appearanceAutomatic: String { tr("appearance_automatic", "Automatic") }
    public static var appearanceLight: String { tr("appearance_light", "Light") }
    public static var appearanceDark: String { tr("appearance_dark", "Dark") }
    public static var textSize: String { tr("text_size", "Text size") }
    public static var disableTransparencies: String {
        tr("disable_transparencies", "Disable transparencies")
    }
    public static var disableTransparenciesFooter: String {
        tr(
            "disable_transparencies_footer",
            "Turn this on to make the interface solid and reduce frosted effects.")
    }
    public static var maxRecentMixes: String { tr("max_recent_mixes", "Recent mixes in sidebar") }
    public static var maxRecentMixesFooter: String {
        tr("max_recent_mixes_footer", "Maximum number of recent mixes shown in the sidebar (5–15).")
    }
    public static var maxRecentSounds: String { tr("max_recent_sounds", "Recent sounds in sidebar") }
    public static var maxRecentSoundsFooter: String {
        tr(
            "max_recent_sounds_footer",
            "Maximum number of recent sounds shown in the sidebar (5–15).")
    }
    public static var collapseCategoriesOnColdOpen: String {
        tr("collapse_categories_on_cold_open", "Start with categories collapsed")
    }
    public static var collapseCategoriesOnColdOpenFooter: String {
        tr(
            "collapse_categories_on_cold_open_footer",
            "On cold launch, sound and mix categories start collapsed (except Custom Mixes).")
    }
    public static var dataSection: String { tr("data_section", "Data") }
    public static var exportPreferences: String { tr("export_preferences", "Export preferences…") }
    public static var exportPreferencesHint: String {
        tr(
            "export_preferences_hint",
            "Save custom mixes, favorite mixes, and favorite sounds to a file")
    }
    public static var exportFailed: String { tr("export_failed", "Export failed") }
    public static var exportFailedMessage: String {
        tr("export_failed_message", "Could not write the file. Check the location and try again.")
    }
    public static var importPreferences: String { tr("import_preferences", "Import preferences…") }
    public static var importPreferencesHint: String {
        tr(
            "import_preferences_hint",
            "Load custom mixes, favorite mixes, and favorite sounds from a file")
    }
    public static var importFailed: String { tr("import_failed", "Import failed") }
    public static var importFailedMessage: String {
        tr("import_failed_message", "Could not read the file or the file format is invalid.")
    }
    public static var aboutSection: String { tr("about_section", "About") }
    public static var version: String { tr("version", "Version") }
    public static var createdBy: String { tr("created_by", "Created by") }
    public static var resetSelectionAndFavorites: String {
        tr("reset_selection", "Reset selection and favorites")
    }
    public static var restoreAllDefaults: String { tr("restore_defaults", "Restore all to defaults") }
    public static var visitWeb: String { tr("visit_web", "Inspired by Moodist on the web") }
    public static var sourceCode: String { tr("source_code", "Source code (GitHub)") }
    public static var buyMeACoffee: String { tr("buy_me_a_coffee", "Buy me a Coffee") }
    public static var askForNewSound: String {
        tr("ask_for_new_sound", "Do you want a new sound? Ask me for it!")
    }
    public static var resetConfirmTitle: String { tr("reset_confirm_title", "Reset selection?") }
    public static var resetConfirmMessage: String {
        tr(
            "reset_confirm_message",
            "All selected sounds and favorites will be cleared. Global volume will not change.")
    }
    public static var restoreConfirmTitle: String { tr("restore_confirm_title", "Restore defaults?") }
    public static var restoreConfirmMessage: String {
        tr(
            "restore_confirm_message",
            "Selection, favorites and global volume will be reset. Playback will stop.")
    }
    public static var cancel: String { tr("cancel", "Cancel") }
    public static var reset: String { tr("reset", "Reset") }
    public static var restore: String { tr("restore", "Restore") }
    public static var menuBar: String { tr("menu_bar", "Menu bar") }
    public static var menuBarShow: String { tr("menu_bar_show", "Show in menu bar") }
    public static var menuBarShowFooter: String {
        tr("menu_bar_show_footer", "Show an icon in the macOS menu bar for quick access.")
    }
    public static var openWindow: String { tr("open_window", "Open Moodist") }
    public static var quit: String { tr("quit", "Quit Moodist") }

    // MARK: - Sidebar
    public static var sidebarFavorites: String { tr("sidebar_favorites", "Favorite Sounds") }
    public static var sidebarFavoriteMixes: String { tr("sidebar_favorite_mixes", "Favorite Mixes") }
    public static var sidebarFavoriteMixesEmpty: String {
        tr("sidebar_favorite_mixes_empty", "No favorite mixes")
    }
    public static var sidebarRecentSounds: String { tr("sidebar_recent_sounds", "Recent Sounds") }
    public static var sidebarRecentSoundsEmpty: String {
        tr("sidebar_recent_sounds_empty", "No recent sounds")
    }
    public static var sidebarRecentMixes: String { tr("sidebar_recent_mixes", "Recent Mixes") }
    public static var sidebarRecentMixesEmpty: String {
        tr("sidebar_recent_mixes_empty", "No recent mixes")
    }
    public static var sidebarFavoritesEmpty: String { tr("sidebar_favorites_empty", "No favorites yet") }
    public static var presetSaveCurrent: String { tr("preset_save_current", "Save as mix") }
    public static var presetApply: String { tr("preset_apply", "Play Mix") }
    public static var presetDelete: String { tr("preset_delete", "Delete mix") }
    public static var editMix: String { tr("edit_mix", "Edit mix…") }
    public static var editMixTitle: String { tr("edit_mix_title", "Edit Mix") }
    public static var editMixSubtitle: String {
        tr("edit_mix_subtitle", "Update the mix name and icon.")
    }
    public static var presetSaveDialogTitle: String { tr("preset_save_dialog_title", "Save Mix") }
    public static var presetNamePlaceholder: String { tr("preset_name_placeholder", "Mix name") }
    public static var saveMixSubtitle: String {
        tr("save_mix_subtitle", "Give your mix a name and pick an icon.")
    }
    public static var saveMixIconMenuHint: String {
        tr("save_mix_icon_menu_hint", "Opens menu to choose an icon for the mix")
    }
    public static var saveMixIconSearchPlaceholder: String {
        tr("save_mix_icon_search_placeholder", "Search SF Symbols…")
    }
    public static var saveMixIconNoResults: String {
        tr("save_mix_icon_no_results", "No icons found for that search.")
    }
    public static var saveMixIconCategoriesHint: String {
        tr("save_mix_icon_categories_hint", "Browse icon categories")
    }
    public static func saveMixIconCategoryTitle(_ categoryId: String) -> String {
        let key = "save_mix_icon_category_\(categoryId)"
        let fallback = saveMixIconCategoryTitleById[categoryId] ?? categoryId
        return tr(key, fallback)
    }
    public static var addToMix: String { tr("add_to_mix", "Add to mix") }
    public static var createNewMix: String { tr("create_new_mix", "Create new mix…") }
    public static var save: String { tr("save", "Save") }

    // MARK: - Search
    public static var search: String { tr("search", "Search") }
    public static var searchPlaceholder: String { tr("search_placeholder", "Search sounds…") }

    // MARK: - Language
    public static var language: String { tr("language", "Language") }
    public static var languageSystem: String { tr("language_system", "System") }
    public static var languageEnglish: String { tr("language_english", "English") }
    public static var languageSpanish: String { tr("language_spanish", "Spanish") }
    public static var languagePortuguese: String { tr("language_portuguese", "Portuguese (Brazil)") }
    public static var languageFooter: String {
        tr(
            "language_footer",
            "Changes take effect after restarting Moodist. System follows your macOS language preference.")
    }
    public static var languageRestartRequiredTitle: String {
        tr("language_restart_required_title", "Restart Required")
    }
    public static var languageRestartRequiredMessage: String {
        tr("language_restart_required_message", "Restart Moodist to apply the selected language.")
    }
    public static var languageRestartQuit: String { tr("language_restart_quit", "Quit Moodist") }
    public static var languageRestartLater: String { tr("language_restart_later", "Later") }

    // MARK: - Dynamic content by id
    public static func soundLabel(_ soundId: String) -> String {
        let key = "sound_\(soundId)"
        let fallback = soundLabelById[soundId] ?? soundId
        return tr(key, fallback)
    }

    public static func categoryTitle(_ categoryId: String) -> String {
        let key = "category_\(categoryId)"
        let fallback = categoryTitleById[categoryId] ?? categoryId
        return tr(key, fallback)
    }

    public static func mixName(_ mixId: String) -> String {
        let key = "mix_\(mixId)"
        let fallback = mixNameById[mixId] ?? mixId
        return tr(key, fallback)
    }

    public static func mixCategoryTitle(_ mixCategoryId: String) -> String {
        let key = "mixcat_\(mixCategoryId)"
        let fallback = mixCategoryTitleById[mixCategoryId] ?? mixCategoryId
        return tr(key, fallback)
    }

    // MARK: - State and accessibility
    public static var stateExpanded: String { tr("state_expanded", "expanded") }
    public static var stateCollapsed: String { tr("state_collapsed", "collapsed") }
    public static var stateSelected: String { tr("state_selected", "selected") }
    public static var stateNotSelected: String { tr("state_not_selected", "not selected") }
    public static func volumeForLabel(_ label: String) -> String {
        String(format: tr("volume_for_label", "Volume for %@"), label)
    }
    public static func countSounds(_ count: Int) -> String {
        String(format: tr("count_sounds", "%d sounds"), count)
    }

    // MARK: - Options additional strings
    public static var dataSectionFooter: String {
        tr(
            "data_section_footer",
            "Reset only clears selection and favorites. Restore also resets global volume.")
    }
    public static var resetSelectionHint: String {
        tr("reset_selection_hint", "Clears selection and favorites")
    }
    public static var restoreDefaultsHint: String {
        tr("restore_defaults_hint", "Resets all settings to defaults")
    }

    // MARK: - Accessibility
    public static var section: String { tr("section", "Section") }
    public static var resizeSidebar: String { tr("resize_sidebar", "Resize sidebar") }
    public static var resizeSidebarHint: String {
        tr("resize_sidebar_hint", "Drag to resize sidebar width")
    }
    public static var expandSection: String { tr("expand_section", "Expand section") }
    public static var collapseSection: String { tr("collapse_section", "Collapse section") }
    public static var collapseAllCategories: String { tr("collapse_all_categories", "Collapse all") }
    public static var expandAllCategories: String { tr("expand_all_categories", "Expand all") }
    public static func categoryExpandHint(_ isExpanded: Bool) -> String {
        isExpanded
            ? tr("category_collapse_hint", "Double tap to collapse category")
            : tr("category_expand_hint", "Double tap to expand category")
    }
    public static var clickToggleSelection: String {
        tr("click_toggle_selection", "Click to toggle selection")
    }
    public static var clickApplyMix: String { tr("click_apply_mix", "Click to play mix") }
    public static var doubleTapPlayMix: String { tr("double_tap_play_mix", "Double tap to play this mix") }
}
