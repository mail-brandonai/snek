# Slither

An original hyper-casual snake arena prototype for Web and Android, built with Flutter and Flame.

## V1 development cycle

V1 is an offline single-player vertical slice intended to establish the game feel:

- continuous pointer/touch steering;
- pellet collection, score, and body growth;
- three deterministic-style roaming bots;
- scrolling arena with a dark hex-grid presentation;
- head-to-body collision and arena-boundary defeat;
- dropped mass after defeat, with distinct boundary/body-collision feedback;
- optional sprinting that trades length for significantly higher movement speed;
- minimal score/length HUD and restart flow;
- live arena minimap showing the player and living bots;
- deterministic bot boundary avoidance, food interest, and nearby-body avoidance;
- explicit pointer/touch steering guidance and terminal-state feedback;
- original placeholder colour variants.

Networking, accounts, monetisation, progression, production art, and multiplayer authority are outside V1.

## Testing strategy

The deterministic simulation under `lib/game/domain` is deliberately separated from Flame rendering. Unit tests cover reset state, movement consequences, collection, growth, defeat, dropped mass, and restart behaviour. Rendering, input feel, pacing, readability, and device performance are exploratory manual feedback items.

GitHub Actions runs formatting, static analysis, the Flutter unit suite, and a release Web build on pull requests targeting `main`. Superseded runs for the same pull request are cancelled. Successful runs publish the runnable Web build as an Actions artifact. Changes should be merged to `main` through a passing pull request; `main` itself is not used as the CI trigger. A trusted follow-up workflow automatically merges a ready, non-stale pull request after the exact `Flutter checks` run passes, while branch protection and required reviews remain authoritative.

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
- Click and hold, or hold Space, to sprint. Moving the mouse while holding does not cancel sprinting. Sprinting is faster but sheds a small amount of length as dropped mass; it is unavailable when no more length can be shed.
- The player starts at the minimum playable length and must collect pellets before sprinting becomes available.
- The snake continues on its current heading when the pointer is centred.
- The player may overlap its own body; only other-snake body collisions defeat the run.
- Collect cyan pellets to grow and increase score; sprint drops are normal-sized orange pellets, while larger orange mass is created when a snake is defeated.
- The minimap marks the player with a ring, living bots with smaller dots, and recent body collisions with short radar pings.
- The live leaderboard shows the five longest living snakes and highlights the player; if the player is outside the top five, their rank is shown beneath it.
- After defeat, read the collision reason and choose `PLAY AGAIN` to reset the seeded opening state.

## V1.1 living arena

The replayable run loop maintains a living arena with deterministic bot respawns
after a short cooldown. Respawn positions are selected away from living snake
bodies when space permits. Natural pellets refill gradually only after the arena
falls below its density threshold, so collection creates a changing food field
instead of an immediate full refill. The HUD reports survival time, live rank,
and a final score, length, time, and rank summary after defeat.

## V1.2 competitive bot pressure

The arena begins with a small bot population and adds one new rival at a time
after a fixed interval until the configured population cap is reached. Defeated
bots still respawn through their existing cooldown, so the population remains
alive while the arena becomes progressively more congested. Bots now use a
bounded intercept target ahead of the player when nearby, avoid living bodies,
and give dropped mass stronger priority than ordinary pellets. This creates
increasing competitive pressure while preserving readable, deterministic
movement and the player's size-versus-maneuverability tradeoff.

## V1.3 collision readability

Sprint drops now use the same compact size as generated pellets, while defeat
drops remain larger and glowing so death locations are easier to identify. Body
collisions also emit a short-lived radar ping on the minimap, including bot
collisions, giving the player a clear signal of where a death occurred.
