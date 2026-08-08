# Slither

An original hyper-casual snake arena prototype for Web and Android, built with Flutter and Flame.

## V1 development cycle

V1 is an offline single-player vertical slice intended to establish the game feel:

- continuous pointer/touch steering;
- pellet collection, score, and body growth;
- three deterministic-style roaming bots;
- scrolling arena with a dark hex-grid presentation;
- head-to-body collision and arena-boundary defeat;
- dropped mass after any defeat, with distinct boundary/body/self-collision feedback;
- minimal score/length HUD and restart flow;
- live arena minimap showing the player and living bots;
- deterministic bot boundary avoidance, food interest, and nearby-body avoidance;
- explicit pointer/touch steering guidance and terminal-state feedback;
- original placeholder colour variants.

Networking, accounts, monetisation, progression, production art, and multiplayer authority are outside V1.

## Testing strategy

The deterministic simulation under `lib/game/domain` is deliberately separated from Flame rendering. Unit tests cover reset state, movement consequences, collection, growth, defeat, dropped mass, and restart behaviour. Rendering, input feel, pacing, readability, and device performance are exploratory manual feedback items.

GitHub Actions runs formatting, static analysis, the Flutter unit suite, and a release Web build on pushes to `main` and pull requests targeting `main`. Successful runs publish the runnable Web build as an Actions artifact. A passing `main` commit is the candidate source for exploratory gameplay captures.

## Local setup

Install the stable Flutter SDK, then run:

```sh
flutter create --platforms=web,android .
flutter pub get
flutter test
flutter run -d chrome
```

The `flutter create` command only adds platform scaffolding to an otherwise platform-neutral source checkout; it does not replace the game code.

## Manual controls

- Move the mouse pointer from the player, or drag on a touch screen, to steer.
- The snake continues on its current heading when the pointer is centred.
- Collect cyan pellets to grow and increase score; orange dropped mass is created when a snake is defeated.
- The minimap marks the player with a ring and living bots with smaller dots.
- After defeat, read the collision reason and choose `PLAY AGAIN` to reset the seeded opening state.
