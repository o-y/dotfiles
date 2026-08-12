# Aegis Configuration Options

Edit `config.json` in this directory. Changes are applied automatically.

Only include settings you want to change - defaults are used for anything not specified.

---

## Master Toggles

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `showNotchHUD` | bool | `true` | Master toggle for entire notch HUD system (volume, brightness, media, device, focus, notifications) |
| `showOverlayHUD` | bool | `true` | Show volume/brightness overlay in the notch |
| `showSystemStatus` | bool | `true` | Show system status panel (WiFi, time, date, battery, focus icon) |
| `showSpaceIndicators` | bool | `true` | Show space indicator buttons in menu bar (Yabai integration) |
| `showAppLauncher` | bool | `true` | Show app launcher button in menu bar |
| `showContextButton` | bool | `true` | Show context/layout actions button in menu bar |

---

## App Switcher

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `appSwitcherEnabled` | bool | `true` | Enable custom Cmd+Tab app switcher |
| `appSwitcherCmdScrollEnabled` | bool | `false` | Enable Cmd+scroll to open/cycle app switcher |
| `appSwitcherShowMinimized` | bool | `true` | Show minimized windows in switcher |
| `appSwitcherShowHidden` | bool | `false` | Show hidden windows in switcher |

---

## Notch HUD - Bluetooth Devices

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `showDeviceHUD` | bool | `true` | Show HUD when Bluetooth devices connect/disconnect |
| `deviceHUDAutoHideDelay` | number | `3.0` | Seconds before HUD auto-hides |
| `excludedBluetoothDevices` | [string] | `["watch"]` | Device names to ignore (case-insensitive substring match) |

---

## Notch HUD - Now Playing

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `showMusicHUD` | bool | `true` | Show Now Playing HUD when music plays (alias: `showMediaHUD`) |
| `musicHUDRightPanelMode` | string | `"visualizer"` | Right panel content: `"visualizer"` or `"trackInfo"` |
| `musicHUDAutoHide` | bool | `false` | Auto-hide after showing track info |
| `musicHUDAutoHideDelay` | number | `5.0` | Seconds before auto-hide (if enabled) |
| `mediaHUDEnableMarquee` | bool | `true` | Enable carousel scrolling for long track titles (disable to reduce CPU) |

---

## Notch HUD - Focus Mode

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `showFocusHUD` | bool | `true` | Show HUD when Focus mode changes |
| `focusHUDAutoHideDelay` | number | `2.0` | Seconds before HUD auto-hides |

---

## App Launcher

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `launcherApps` | [string] | See below | Bundle IDs for apps in the launcher (scroll to select) |

**Default launcherApps:**
```json
["com.apple.finder", "com.apple.systempreferences", "com.apple.ActivityMonitor", "com.apple.Terminal"]
```

To find an app's bundle identifier, run in Terminal:
```bash
osascript -e 'id of app "AppName"'
```

---

## Notch HUD - Notifications

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `showNotificationHUD` | bool | `true` | Show system notifications in the notch HUD |
| `notificationHUDAutoHide` | bool | `true` | Auto-hide notification HUD after delay |
| `notificationHUDAutoHideDelay` | number | `8.0` | Seconds before notification auto-hides |
| `notificationExcludedApps` | [string] | See below | Bundle IDs or app names to exclude from notification HUD |

**Default notificationExcludedApps:**
```json
["com.apple.controlcenter", "com.apple.donotdisturbd", "com.apple.FocusSettings"]
```

Notifications from these apps will be silently ignored. This prevents duplicate HUDs (e.g., Focus mode notifications are already shown by the Focus HUD).

You can add bundle identifiers (e.g., `"com.apple.mail"`) or partial app name matches (e.g., `"Slack"`).

---

## Desktop

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enableWallpaperBlur` | bool | `false` | Blur desktop wallpaper when windows are focused on the current space |
| `wallpaperBlurIntensity` | number | `0.85` | Blur overlay intensity (0.1 to 1.0) |

---

## Appearance

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `appTheme` | string | `"dark"` | Theme mode: `"dark"`, `"light"`, or `"system"` |
| `customBackgroundColor` | string | `null` | Custom background color as hex (e.g. `"#1A1A2E"`) |
| `customTextColor` | string | `null` | Custom text/icon color as hex (e.g. `"#E0E0FF"`) |
| `customBorderColor` | string | `null` | Custom border color as hex (e.g. `"#4A4A6A"`) |
| `colorPresets` | [object] | `[]` | Saved color presets with name, backgroundColor, textColor, borderColor |

---

## Menu Bar

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `maxAppIconsPerSpace` | int | `3` | Max window icons per space before overflow menu |
| `excludedApps` | [string] | `["Finder", "Aegis"]` | Base apps to hide from space indicators (launcher apps are automatically excluded) |
| `showAppNameInExpansion` | bool | `false` | Show app name below window title when expanded |
| `autoExpandFocusedWindow` | bool | `true` | Automatically expand the focused window's title |
| `useSwipeToDestroySpace` | bool | `true` | Enable swipe-up gesture to destroy spaces |

---

## Behavior

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `launchAtLogin` | bool | `true` | Start Aegis when macOS starts |
| `enableLayoutActionHaptics` | bool | `true` | Haptic feedback on layout actions |
| `expandContextButtonOnScroll` | bool | `true` | Show label when scrolling context button (disable to save CPU) |
| `windowIconExpansionAutoCollapseDelay` | number | `2.0` | Seconds before expanded window collapses |

---

## Interaction Thresholds

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `dragDistanceThreshold` | number | `3` | Pixels before drag starts |
| `swipeDestroyThreshold` | number | `-120` | Swipe distance to destroy space |
| `scrollActionThreshold` | number | `3` | Scroll amount for action selection |

---

## Animation Timings

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `stateTransitionDuration` | number | `0.25` | Duration for state changes |
| `notchHUDFadeInDuration` | number | `0.2` | HUD fade-in duration |
| `notchHUDFadeOutDuration` | number | `0.3` | HUD fade-out duration |

---

## Visual Customization

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `activeSpaceBgOpacity` | number | `0.18` | Background opacity for active space |
| `hoveredSpaceBgOpacity` | number | `0.15` | Background opacity for hovered space |
| `inactiveSpaceBgOpacity` | number | `0.12` | Background opacity for inactive space |

---

## System Status

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `dateFormat` | string | `"long"` | Date format: `"long"` (Mon Jan 13) or `"short"` (13/01/26) |
| `showFocusName` | bool | `false` | Show Focus mode name alongside symbol |

---

## Export Full Config

To see all current values, you can export the full config by adding this to a Swift file or running in Xcode console:

```swift
AegisConfig.shared.saveToJSONFile()
```

This will overwrite `config.json` with all settings and their current values.