# Using Moodist on iPhone

**Sounds** contains the complete offline catalog. Tap a sound to add/remove it from the running selection; use its favorite button or context menu to organize it. Search uses localized names. Categories can be collapsed individually or together; the app remembers navigation anchors.

**Mixes** contains curated combinations. Selecting a mix applies its tracks and volumes. **Library** contains custom mixes, ordered favorites and separate recent lists. Use Edit/reorder actions for favorites. A custom mix can be saved from the player, edited via its menu or created by adding a sound from its context menu.

The glass mini-player stays above the tab bar. Tap its title to open the player; play/pause preserves the selection. The player exposes global and individual track volume, shuffle, next mix, track removal, save-as-mix and AirPlay output selection. The app's global volume is separate from the phone's system volume. Drag or scroll the player to reach additional controls; accessibility text sizes request a large sheet.

## Timers and background audio

Sleep offers presets or hours/minutes/seconds. It stops playback at its deadline and cancels automatic rotation. Notifications are optional and requested when scheduling; denying them does not prevent foreground/audio-running sleep logic.

Automatic mixes rotate every 5–60 minutes. Enable custom-only mode to use your saved mixes; it cannot start with an empty custom list. A paused app never starts playback merely because a rotation becomes due. Sleep takes precedence over automatic rotation and interruption recovery.

While iOS allows the playback audio session to run, sound can continue in the background and with a locked screen. Calls, Siri or route changes can interrupt it. Disconnecting headphones pauses audio; a manual pause prevents automatic resumption. After an interruption, session and engine state are reconciled before playback resumes.

Settings offers two audio policies. Normal playback requests system media ownership; mixing with other apps allows audio coexistence and relinquishes Moodist's remote commands/Now Playing to avoid taking another player's controls. iOS determines actual media ownership. The optional Next command can be disabled. AirPlay/Bluetooth availability depends on system routes and hardware.

Timers store absolute deadlines, not promises of background execution. When suspended/terminated without active audio, iOS does not guarantee an exact callback. Moodist reconciles elapsed deadlines on activation; it never autoplays after a cold launch or replays every missed rotation. A pending local notification does not itself grant execution or start audio.

## Preferences and transfer

Settings includes theme, accent, transparency, language (system/en/es/pt-BR), recent limits, collapse behavior and audio policy. The transparency toggle affects app-owned surfaces; the system controls its native bars and accessibility adaptations.

Export writes a JSON v1 preferences document compatible with Mac. Import through Files validates and sanitizes it before asking to replace supported preferences. Unknown IDs and invalid values cannot partially modify state; newer formats fail explicitly. Share exports a temporary document and cleans it up when the sheet finishes. Files belong to your chosen provider; the app does not supply a sync server.

Reset Selection and Favorites clears those items; Restore Defaults is the broader reset, including playback/timers and stored app preferences. Both require confirmation. Read the confirmation scope before accepting. Device-exclusive window positions and Mac menu-bar preferences have no iPhone switches.
