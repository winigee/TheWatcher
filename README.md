# TheWatcher

A standalone macOS desktop time-tracking client for fee earners. No backend
server, no cloud sync — everything lives in a local SQLite store in the user's
Application Support directory.

TheWatcher pairs a conventional administrative window with a set of floating
desktop tiles (`NSPanel`s layered on the desktop) so that starting, stopping
and annotating timed work is a one-click, friction-free action.

## Features

- **Hierarchical rate resolution.** Each time entry's rate is resolved with a
  strict fallback — entry override → matter rate → client rate → fee earner
  default — and then *frozen* onto the entry so historical reports stay stable.
- **Desktop tiles.** A floating grid of the 5–10 most recently accessed matters,
  each showing client, matter, today's accumulated time and a play/stop toggle.
- **Single active timer (mutual exclusion).** Starting a timer on one matter
  automatically stops any timer already running on another.
- **Narrative prompt.** Stopping a timer surfaces a transient prompt to capture
  what you worked on; skip it and the entry is saved with a blank narrative for
  later completion.
- **Dashboard.** Today's entries in a chronological table with inline editing of
  narrative, duration and applied rate.
- **Clients & Matters CRUD** with level-specific rate overrides and the fee
  earner's default base rate.
- **CSV export** of a date range, flattened to one row per entry.

## Project layout

```
Sources/TheWatcher/
  App/          App entry point and AppKit delegate
  Persistence/  Core Data stack, programmatic model, entity classes
  Models/       RateResolver (the rate fallback logic)
  State/        TimerManager (timekeeping + mutual exclusion)
  Views/        Dashboard, Clients & Matters, Export, root navigation
  Widgets/      Floating desktop tile panel + SwiftUI tile grid
  Export/       CSVExporter
  Support/      Formatting helpers
Tests/TheWatcherTests/
  RateResolverTests  Unit tests for the rate fallback
```

The Core Data model is defined **in code** (`Persistence/ManagedObjectModel.swift`)
rather than via an Xcode `.xcdatamodeld` file, so the schema is fully
reviewable in source control.

## Building

Requires macOS 13+ and a recent Swift toolchain (Xcode 15+).

```bash
swift build      # compile
swift test       # run the rate-resolution unit tests
swift run        # launch the app
```

> **Note:** to ship a proper double-clickable `.app` bundle (with an
> `Info.plist`, app icon and code signing) open the package in Xcode and add a
> macOS App target, or wrap the built executable in a bundle. The SPM
> executable target above is intended for development and running from the
> command line.

## Data model

| Entity     | Key attributes                                            |
| ---------- | --------------------------------------------------------- |
| FeeEarner  | `id`, `name`, `baseRate`                                  |
| Client     | `id`, `name`, `overrideRate?`                             |
| Matter     | `id`, `name`, `overrideRate?`, `lastAccessed`, → Client   |
| TimeEntry  | `id`, `date`, `duration`, `narrative`, `appliedRate`, → Matter |

`duration` is stored in decimal hours (e.g. `1.5`). `appliedRate` is the rate
resolved at creation time. A time entry's total value is `duration × appliedRate`.
