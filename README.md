# Swipe Out

**Clean up your photo library one swipe at a time.** Swipe Out shows your photos
one by one, Tinder-style — swipe to decide what stays and what goes, then delete
the lot in a single tap.

Built with SwiftUI and Swift 6, on-device and private by design.

<!-- Add App Store badge + screenshots here once published -->

---

## Features

- **Swipe to decide** — swipe right to mark a photo for deletion, left to keep it,
  with live color feedback tinting the photo itself.
- **Mark now, delete later** — nothing is removed until you confirm; deletion runs
  through iOS's native confirmation dialog.
- **Multi-level undo** — step back through your decisions one by one, from anywhere,
  even the final screen.
- **Freed-space counter** — see how much storage you'll reclaim as you go, and how
  much you actually freed when you're done.
- **Tap or swipe** — large Keep / Delete buttons mapped to the same directions as
  the swipes, for anyone who prefers tapping.
- **Fast & fluid** — neighbouring images are preloaded so browsing stays instant,
  with smooth card animations and haptic feedback throughout.
- **Private** — everything runs on-device. No account, no ads, no analytics, no data
  collected.
- **Accessible & localized** — full VoiceOver support, available in English and
  Spanish.

## Tech stack

- **Swift 6** with strict concurrency (actors, `@Sendable`, `@MainActor`)
- **SwiftUI** + the `@Observable` macro
- **PhotoKit** — `PHAsset`, `PHPhotoLibrary`, `PHCachingImageManager`
- **Swift Testing** for unit tests
- **String Catalogs** (`.xcstrings`) for localization

## Architecture

Swipe Out follows **MVVM with a protocol-oriented service layer**. The goal:
keep all the decision logic free of PhotoKit so it can be unit-tested without a
device or the photo library.

```
Models/         PhotoItem                          — plain, PhotoKit-free model
Services/       PhotoLibraryService (protocol)     — the boundary
                PhotoKitLibraryService (actor)     — the only file that imports PhotoKit
                ImageLoader                         — id-based cache + neighbour preloading
ViewModels/     ReviewViewModel                     — pure decision logic, injected service
Views/          ContentView, ReviewView, FinishedView
Components/     SwipeCardView, CircleActionButton, StatusView, DeleteButton
Theme/          Theme                               — design tokens (color, spacing, type)
Utilities/      Haptics
```

**Key decisions**

- **Dependency injection via a protocol** — `ReviewViewModel` receives a
  `PhotoLibraryService`. The app injects the real PhotoKit-backed actor; tests inject
  an in-memory mock. The ViewModel imports zero PhotoKit.
- **Concurrency** — the PhotoKit layer is an `actor` running off the main thread;
  the ViewModel is `@MainActor`. Framework callbacks (authorization, image loading,
  change requests) are bridged with `withCheckedContinuation` and marked `@Sendable`
  to satisfy Swift 6's strict checking.
- **Bounded memory** — the image cache keeps only a small window (±3) around the
  current photo, so memory stays flat whether the gallery has 100 or 100,000 photos.
- **Scales to large galleries** — photo file sizes are computed lazily (only for
  photos the user actually marks), so the app loads in near-constant time regardless
  of gallery size.
- **Derived state** — the freed-space total is a computed property over the marked
  set, so undo can never desync the count.

## Testing

Unit tests cover the decision logic through an in-memory mock service — no simulator,
no photo library, milliseconds to run. The critical test verifies that **only the
marked photos are deleted, never any others**.

```bash
# In Xcode
Cmd + U
```

## Requirements

- iOS 18.0+
- Xcode 16+

## Privacy

Swipe Out runs entirely on-device. It never uploads, shares, or collects any photos
or data — it only reads your library to display photos and deletes the ones you
choose. Deleted photos go to iOS's "Recently Deleted" album (recoverable for 30 days).

Full policy: <https://regaloomar.github.io/SwipeOut/>

## Roadmap

- Filter by album, date, or screenshots
- Video support
- Duplicate detection
- Pro unlock (one-time purchase) for the above

## License

Copyright © 2026 Omar Alejandro Regalado Mendoza. All rights reserved.
