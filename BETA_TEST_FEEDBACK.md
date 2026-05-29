# Closed Beta Feedback

This document collects feedback and follow-up improvements discovered during the first Google Play closed beta. Items here are intentionally practical and should be moved into the roadmap or issues once scoped.

## Mobile UX Fixes

- [ ] Onboarding navigation controls overlap the Android system navigation bar on some devices.
  - Move the Back and Start buttons higher or wrap the onboarding footer in a safe-area aware layout.
  - Verify with gesture navigation and three-button navigation.

- [ ] Pressing the Android system Back button from the language selection screen closes the app.
  - Expected behavior: return to the previous settings screen, return to Home, or close the settings panel with a leftward/back navigation feel.
  - The app should not exit from this nested settings flow.

- [ ] Replace the GitHub, Instagram, and LinkedIn footer icons with recognizable brand icons.
  - Current icons are not clear enough for beta users.
  - Keep the footer subtle, but make link targets visually understandable.

## Onboarding Improvements

- [ ] Auto-play the introductory video on the onboarding video page.
  - When the video ends, show a replay button.
  - Keep the current behavior where tapping the video opens it fullscreen.
  - Verify that audio/video behavior is acceptable on Android and does not feel intrusive.

## Responsive Layout Improvements

- [ ] Open the navigation menu by default on medium and wide layouts.
  - Target: tablet, desktop, and web/tablet-like widths.
  - Users can still close it manually through the menu button.
  - Keep compact phone layouts closed by default.

## Notes

These fixes should be treated as post-beta polish before widening the release. The first two mobile UX items are higher priority because they affect navigation and perceived app stability.
