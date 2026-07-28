# Swipe Out

Clean up your photo library one swipe at a time. Swipe Out shows your photos one
by one, Tinder-style — swipe to decide what stays and what goes, then delete the
lot in a single tap.

## Features

- **Swipe to decide** — swipe right to mark a photo for deletion, left to keep it,
  with live color feedback on the photo itself.
- **Mark now, delete later** — nothing is removed until you confirm. Marked photos
  pile up and are deleted together through the system's native confirmation dialog.
- **Multi-level undo** — changed your mind? Step back through your decisions one by
  one, from any point, even the final screen.
- **Freed-space counter** — see how much storage you'll reclaim as you go, and how
  much you actually freed when you're done.
- **Tap or swipe** — big Keep / Delete buttons for anyone who prefers tapping,
  mapped to the same directions as the swipes.
- **Fast & fluid** — neighbor images are preloaded so browsing stays instant, with
  smooth card animations throughout.
- **Start over** — review your whole gallery again without leaving the app.

## Tech

- **SwiftUI** — fully declarative UI, dark-themed with a small design-token system.
- **PhotoKit** — reading, loading and deleting assets from the photo library.
- **Swift 6** — strict concurrency, `@Observable`, async/await.
- **Design tokens** — colors, spacing, radii and typography centralized in `Theme`.

## Requirements

- iOS 26.0+
- Xcode 16+

## Project structure

- `PhotoManager/` — state, photo library access, decisions, deletion, image loading
- `Components/` — reusable views (`SwipeCardView`, `CircleActionButton`, `StatusView`)
- `Theme/` — design tokens (colors, spacing, radius, typography)
- `ContentView.swift` — screen states: loading, review, finished, denied

## Privacy

Swipe Out runs entirely on-device. It never uploads, shares or collects any of your
photos or data — it only reads your library to show photos and deletes the ones you
choose. Deleted photos go to the system "Recently Deleted" album, where iOS keeps
them for 30 days.

## Status

In active development, working toward an App Store release. Roadmap: architecture
refactor with unit tests, localization (EN/ES), accessibility, and app polish.

## License

Copyright © 2026 Omar Regalado. All rights reserved.
