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
collisions, giving the player a clear signal of where a death occurred. The
collision event also produces a brief HUD-edge shimmer, while active sprinting
uses a pulsing aura around the player snake.

## V1.4 reward and sprint readability

Natural pellets and sprint drops each award one length point. Defeat drops are
larger and award three points each, making predation more rewarding than
collecting ordinary or self-generated mass. Sprint drain is paced more gently
so acceleration remains useful without consuming length too aggressively.
Newly acquired length is expressed through movement: the tail projects
backward through the movement trail at a controlled fraction of head travel,
producing a smooth growth transition instead of an immediate backward tail
jump or a visibly stationary tail.

## V1.5 population, bot variety, and boundary readability

The arena now builds toward a larger population more quickly, with a
deterministic roster of small, medium, large, defensive, aggressive,
opportunistic, and wandering bots. Large bodies remain slower and easier to
intercept, while exceptionally large bots retreat toward the boundary and are
removed from play before they become an unlimited source of high-value prey.
Boundary exits never create dropped mass. The arena boundary is marked by a
high-contrast red perimeter, an inner warning band, boundary ticks, and a HUD
edge warning. Sprint and defeat drops inherit the color of the snake that
created them; generated pellets remain cyan.

## V1.6 threat pacing

The population ramp now reaches its cap sooner, while nearby bots use a wider
interception radius and a stronger lead target. Bots also gain a modest growth
multiplier from food, allowing medium and large rivals to emerge during longer
runs without removing the smaller and more vulnerable size tiers.

## V1.7 paced tail growth

Snake growth is expressed through travel rather than an immediate tail jump.
New length projects backward through the movement trail at a controlled rate,
while the tail continues to translate with the head instead of remaining
stationary during the transition.

## V1.8 stable body geometry

Logical length updates immediately for score, rank, bot scaling, and sprint
eligibility, but newly acquired length is not inserted into collision or render
geometry as overlapping placeholder segments. Existing segments remain sampled
at normal spacing from the movement trail. Growth is expressed only through a
fractional terminal tail extension until each new segment is fully travelled,
so queued growth no longer compresses or reshapes the entire snake body.