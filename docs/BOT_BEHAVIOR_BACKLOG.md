# Bot behavior backlog after V1.27

V1.27 is the final bot-behavior-focused iteration before map development.
Items below are deliberately deferred unless gameplay reveals a major
regression, correctness problem, or material performance issue.

## Deferred improvements

- Tune responder recruitment by map region once map geometry and traversal
  constraints exist.
- Let bots learn recurring player feint sequences across a run without using
  hidden state or exceeding the bounded planner budget.
- Expand food-bait portfolios after map hazards and high-value resource zones
  establish meaningful spatial context.
- Add longer-horizon cooperation for multiplayer only after the authoritative
  networking model is defined.
- Revisit disposition-specific hunter handoffs if map chokepoints make the
  current one-or-two-hunter cap too weak or too oppressive.

## Re-entry gate

Bot work should resume only for a reproducible major regression, a safety or
collision-discipline defect, a frame-budget violation, or evidence that map
mechanics cannot be evaluated with the accepted V1.27 behavior baseline.
