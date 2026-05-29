# Closed Beta Feedback

This document collects feedback and follow-up improvements discovered during the first Google Play closed beta. Items here are intentionally practical and should be moved into the roadmap or issues once scoped.

## Mobile UX Fixes

- [x] Onboarding navigation controls overlap the Android system navigation bar on some devices.
  - Move the Back and Start buttons higher or wrap the onboarding footer in a safe-area aware layout.
  - Implemented with a safe-area aware onboarding body.
  - Still verify with gesture navigation and three-button navigation on a real Android device.

- [x] Pressing the Android system Back button from the language selection screen closes the app.
  - Expected behavior: return to the previous settings screen, return to Home, or close the settings panel with a leftward/back navigation feel.
  - The app should not exit from this nested settings flow.
  - Implemented by routing Android Back from Settings to Home.

- [x] Replace the GitHub, Instagram, and LinkedIn footer icons with recognizable brand icons.
  - Current icons are not clear enough for beta users.
  - Keep the footer subtle, but make link targets visually understandable.
  - Implemented with brand icons from `font_awesome_flutter`.

## Onboarding Improvements

- [x] Auto-play the introductory video on the onboarding video page.
  - When the video ends, show a replay button.
  - Keep the current behavior where tapping the video opens it fullscreen.
  - Verify that audio/video behavior is acceptable on Android and does not feel intrusive.
  - Implemented with inline auto-play and replay after the video ends.

## Responsive Layout Improvements

- [ ] Refactor the medium/wide navigation into a persistent shell.
  - Target: tablet, desktop, and web/tablet-like widths.
  - Users should still be able to close it manually through the menu button.
  - Keep compact phone layouts closed by default.
  - Current implementation opens the menu on wide layouts, but web navigation
    still recreates the app chrome and creates an unpleasant loading effect.
  - The side navigation is also too wide; target about `220-240px`.
  - See `NAVIGATION_SHELL_REFACTOR.md`.

## Notes

These fixes should be treated as post-beta polish before widening the release.

Remaining beta polish:

- [ ] Verify onboarding navigation controls on a real Android device with gesture navigation and three-button navigation.
- [ ] Verify Android Back from Settings on a real Android device.
- [ ] Verify onboarding video auto-play, replay, and fullscreen behavior on a real Android device.
- [ ] Implement and verify persistent `ShellRoute` navigation on tablet,
      desktop, and resized web layouts.
- [ ] Optional: evaluate whether an immersive fullscreen mode is worth adding for specific media screens. Avoid enabling it app-wide unless beta feedback clearly asks for it.
