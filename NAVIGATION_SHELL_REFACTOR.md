# Navigation Shell Refactor

This document defines the next navigation/layout refactor for Exlser.

Status: implemented. Keep this document as the reference for regression checks
and future shell improvements.

## Current Problem

The current responsive navigation works functionally, but on web and desktop it
does not feel stable enough.

Observed behavior:

- The side menu and app bar are recreated when navigating between routes.
- On web this looks like the whole page reloads, even when only the central
  content should change.
- The persistent side menu is too wide for the current information density.
- The app bar and side menu are visually stable elements, so they should not
  appear to reload during normal navigation.

Root cause:

```text
Each page owns its own AppScaffold
↓
Menu item calls context.go(...)
↓
GoRouter changes route
↓
The route page rebuilds its own AppScaffold
↓
App bar + side menu are recreated with the page
```

## Target Behavior

Exlser should use a persistent application shell:

```text
AppShell
├── AppTopBar
├── desktop/tablet side navigation
└── route content
```

Only the route content should change when navigating between:

```text
Home
Works
Settings
Dataset
Multi-dataset analytics
```

The top bar and side navigation should remain mounted and visually stable.

## Proposed Architecture

Use `ShellRoute` from `go_router`.

Target structure:

```text
GoRouter
└── ShellRoute
    ├── AppShell
    │   ├── AppTopBar
    │   ├── AppSideNavigation
    │   └── child route content
    ├── HomeView
    ├── DatasetsListView
    ├── SettingsView
    ├── DatasetView
    └── MultiDatasetAnalyticsView
```

After this refactor, regular views should render page content only. They should
not create their own full app scaffold.

## Responsive Rules

Phone:

- Use the current modal drawer behavior.
- The menu opens only when the user taps the menu button.
- Keep the content width maximized.

Tablet / desktop / web:

- Use a persistent side navigation.
- Open by default.
- Allow the user to collapse or reopen it from the menu button.
- Reduce open width to about `220-240px`.
- Optional later: add a collapsed icon-only width around `72px`.

## Contextual App Bar Actions

The shell app bar must support actions that belong to the current route.

Known actions:

- `DatasetView`: export/share action.
- `MultiDatasetAnalyticsView`: future export/share action.

Important constraint:

`DatasetView` currently owns its `DatasetBloc`. A shell-level app bar cannot
read inherited state from a child route directly. The refactor must therefore
provide a clean way for route content to register contextual actions.

Preferred direction:

- Add a small shell action state/registry, likely through Riverpod.
- Route content registers app bar actions when mounted and clears them when
  disposed.
- Dataset-specific actions can receive the needed bloc/service references
  explicitly instead of relying on an inherited context from the shell.

Possible implementation shape:

```text
AppShellAction
├── key
├── tooltip
├── icon
└── onPressed
```

or, if widget flexibility is needed:

```text
AppShellActionBuilder
└── Widget build(BuildContext shellContext)
```

The chosen implementation must avoid stale actions when leaving a route.

## Navigation Rules

- Do not call `context.go(...)` when the user taps the already active route.
- Highlight the active route in the side navigation.
- Keep side navigation and top bar mounted across route changes.
- Preserve mobile drawer behavior.
- Preserve browser back/forward behavior on web.

## Implementation Order

1. Introduce `AppShell`.
2. Move top bar and side navigation into `AppShell`.
3. Convert route setup to `ShellRoute`.
4. Replace page-level `AppScaffold` usage for shell routes.
5. Add active route highlighting.
6. Reduce side navigation open width.
7. Add contextual app bar action registry.
8. Move `DatasetView` export/share action into shell app bar through the
   contextual action registry.
9. Reserve the same mechanism for future `MultiDatasetAnalyticsView` actions.
10. Verify mobile drawer behavior, desktop persistent navigation, and web
    browser back/forward navigation.

## Definition of Done

- Navigating between shell routes changes only the central content visually.
- App bar and side navigation do not flicker or appear to reload on web.
- Side navigation width is compact enough for laptop screens.
- Mobile keeps the drawer interaction.
- `DatasetView` still exposes export/share from the app bar.
- Future `MultiDatasetAnalyticsView` can expose its own share/export action
  through the same shell action system.
