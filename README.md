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

## V1.9 intentional bot sprinting

The existing deterministic bot roster now has a movement resource in addition
to its disposition-specific steering. Aggressive bots can sprint to complete a
viable interception, opportunistic bots can contest fresh defeat mass, wandering
foragers can commit to unusually nearby natural food, and defensive or retreating
bots can burst away from danger. Sprinting is bounded by a duration, cooldown,
minimum length, shed-mass cost, and the existing arena boundary rules. Bot
growth remains capped so sprint-capable rivals do not grow without limit, while
player sprint economics and V1.8 body geometry remain unchanged.

## V1.10 shared actor telegraphs

Bots and future human players now use the same public-facing movement signals.
Sprint anticipation and active sprint pulses are visible before and during
acceleration, while actor intent is classified from observable position,
heading, movement commitment, and nearby food or actors rather than hidden bot
decisions. The simulation publishes bounded telegraph events and projected-path
threat signals, and the HUD/minimap expose them without bot-only warnings.
These signals are actor-neutral so a future networked player can emit the same
telegraphs through ordinary public movement state. Collision rules, sprint
economics, bot dispositions, population, and V1.8 body geometry remain
unchanged.

## V1.11 tactical bot movement

Bot steering now changes tactics on bounded, deterministic intervals instead of
following one continuous turn curve. Depending on its public situation, a bot
may feint with a zig-zag, cut off a moving player, flank from a lateral line,
approach the space between the player's head and tail, disengage through an
anti-encirclement escape vector, or position beyond food as a baiting trap.
Short speed commitments and braking phases create readable speed-then-slow
interactions without granting hidden information or unlimited acceleration.
The existing actor-neutral telegraph state continues to describe the movement
that is actually visible in the arena.

## V1.13 arena control

Defeat drops are now treated as shared strategic objectives rather than only
nearby food. Bots detect dense defeat fields at a longer range, assign a
deterministic claimant, and use separated harvesting or blocking lanes when a
player is approaching the field. Opportunistic and aggressive bots can sprint
to contest a fresh collision field, while the remaining bots avoid piling into
the same centre line.

Bot route avoidance now projects nearby bodies and peer heads forward using
their current public movement. This creates an early yield or side-step before
two bots select intersecting lanes, while deliberate body traps and ordinary
collision rules remain valid.

The tactical HUD is optional and disabled by default. The base score, rank,
leaderboard, minimap, boundary, collision, and restart feedback remain visible;
the player can enable the extra threat and tactical minimap signals with the
`TACTICS HUD` control.

## V1.12 reactive bot defense

Bots now share a bounded engagement model around the player's publicly visible
heading and position. The fastest eligible rival claims the primary projected
intercept lane, while additional rivals approach from separated flank lanes
instead of converging on the same point. This makes a long, passive player path
a usable opportunity rather than a low-priority background signal.

Bot steering also samples its own short future route against nearby actor bodies
and applies an early side-step when that route is converging with another snake.
Peer separation reduces same-cluster head approaches before they become
collision events, while the ordinary collision rules and visible actor
telegraphs remain unchanged. These changes reduce accidental bot-on-bot and
bot-on-player deaths without making bots immune to deliberate body traps.

## V1.14 adaptive pursuit defense

Bot pursuit is now interruptible. Each bot continually re-plans from the
player's current public heading and position; a sharp heading reversal or
lateral evasion invalidates the previous tactical commitment instead of
leaving the bot on a stale intercept lane.

Projected player-body crossings have priority over pursuit and sprinting. When
an intercept lane becomes unsafe, the bot cancels its sprint, takes a bounded
side-step, and briefly disengages before selecting a new approach. This keeps
aggressive pressure possible while preventing the kamikaze behavior where a
bot continues through the player's defensive body position.

## V1.15 adaptive engagement and arena denial

Bot pursuit now uses a continuously recomputed engagement plan rather than a
stale tactical lane. Eligible bots receive separated public roles: one can
claim a safe projected intercept, others use lateral flank or denial lanes,
and each candidate is rejected when its projected route crosses the player's
body or another bot's route. This lets bots react to gradual as well as sharp
player evasions while preserving visible, actor-neutral movement.

Large bots no longer retire permanently when they cross the retreat length.
Retreat is a situational safety response used near the boundary, under body
pressure, or on an unsafe player crossing; otherwise the bot can re-enter
engagement, contest a defeat field, and help deny the player's feeding route.
The result is stronger pressure without making bots collision-immune or
granting them hidden information.

## V1.16 closed-loop engagement

Bot pursuit now closes the loop around the player's observed route. The
simulation estimates recent heading change and projects a short curved route,
so bots can choose an approach around a turn instead of repeatedly aiming at a
stale straight-line intercept.

Engagement is represented as bounded public-state modes: observe, intercept,
screen, deny, harvest, abort, and re-plan. A player evasion advances the bot to
a fresh lane, while unsafe projected body crossings still take precedence over
attack pressure. Bots also coordinate around contested defeat fields by giving
the nearest claimant a harvesting lane and assigning nearby rivals to deny or
screen the player's approach.

The planner remains deterministic, candidate-scored, and actor-neutral. It
uses only positions, headings, bodies, speeds, food fields, and collision risk
already available to the simulation; it does not grant bots hidden warnings or
future player input.

## V1.17 geometry-aware pressure

Bot engagement now scores explicit geometry around the player's head, body
midpoint, tail, and head-to-tail gap. Bots can approach a side lane, screen an
exit, or pressure the gap rather than repeatedly aiming at the same projected
head point. Each attack candidate is also scored for a lateral or retreating
abort route, so defensive avoidance can interrupt a genuinely unsafe attack
without cancelling every offensive approach.

All dropped mass is now eligible for strategic field control, including sprint
trails as well as defeat drops. Dense fields can therefore become contested
resource zones even when no snake has recently died there; bots assign approach,
harvest, and denial lanes around the same public field.

When the player creates a large size gap, bot food growth and effective growth
capacity scale within bounded limits. This keeps the opposition capable of
catching up during a long run without removing the deterministic roster,
collision rules, or actor-neutral public telegraphing.

## V1.18 formation pressure and collision discipline

Engaged bots now receive a persistent, deterministic formation lease instead
of independently recomputing the same approach. The formation assigns a lead
cutoff, left and right screen lanes, and a resource guard around contested
dropped-mass fields. Each lane is continuously recomputed from the player's
public route, but the role remains stable long enough to produce visible
pressure and a usable attack/abort sequence.

Peer collision risk is now a hard safety decision rather than another additive
steering term. Bots project peer heads and bodies, cancel sprint or attack
commitments when a crossing becomes unsafe, and yield through deterministic
side-steps before ordinary collision resolution. Deliberate body traps remain
possible because the safety layer uses bounded public projections and does not
make bots collision-immune.

The adaptive growth response is stronger but bounded, allowing bots to recover
some size parity when the player has created a large lead. The player can still
outmaneuver or defeat bots; the intended change is that bot-on-bot deaths no
longer become a free food strategy for a waiting player.

## V1.19 performance and opposition balance

Body reconstruction now samples the movement trail in one forward pass per
actor instead of rescanning the trail for every visible segment. This keeps
growth and long turns from creating a quadratic per-frame geometry cost.

Dropped mass is bounded by a configurable population cap and lifetime. The
strategic field index is rebuilt from spatial buckets once per simulation step,
so bot planning no longer recomputes an all-pairs cluster search for every bot.
Expired or excess drops are removed before they can accumulate into an
unbounded render and planning workload.

When the player maintains a large size lead after the opening phase, living
bots receive bounded catch-up growth toward a fraction of the player's public
length. This gives the opposition a real predator-capable size floor while
preserving the existing maximum, movement penalties, collision rules, and
actor-neutral telegraphing. Bots can still be outmaneuvered or defeated; the
player can no longer win indefinitely by waiting for undersized bots to fail
nearby.

## V1.20 bounded tactical planning

Movement trails are maintained in append order and trimmed with bounded slack,
removing the repeated front-insertion cost that became visible as long snakes
filled the arena. Body geometry still follows the same public path, spacing,
growth expression, and collision rules, but the trail work is now amortized.

Bot tactical decisions are recomputed on a bounded cadence instead of rebuilding
the full engagement stack on every movement substep. A sharp public player turn
still invalidates the cached plan immediately. Each planning pass uses a shared
priority order and route reservations: emergency peer deconfliction and player
body evasion take precedence over attack, resource contest, and wandering, while
attack candidates retain an explicit abort route. This keeps pursuit intentional
without allowing food steering or another bot's approach to dilute a necessary
evasion.

## V1.21 indexed busy-state performance

The simulation now builds shared spatial buckets after each movement substep for
living body segments, natural pellets, and dropped mass. Food collection and
nearby food queries use local buckets, while threat, predictive avoidance,
player-route risk, peer-route risk, and body collision checks avoid walking the
entire world when the relevant geometry is nearby.

Bot planning cadence expands within a bounded interval when total body and food
load becomes high. Existing plans continue to move the bots between planning
passes, while sharp public player turns still force an immediate re-plan. This
reduces synchronized tactical bursts without hiding information or weakening
emergency evasion.

Busy rendering also samples exceptionally long bodies at a bounded stride,
with overlapping-radius compensation preserving a continuous silhouette. The
planner cancels a compromised pursuit earlier, resets the engagement state for
a fresh lane, and retains the existing public telegraphs, deliberate attack
routes, and ordinary collision rules.
