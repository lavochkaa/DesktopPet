# Pet Brain v1

## Goal

Make the desktop pet feel curious, calm, and occasionally playful without an LLM. Its decisions must be local, deterministic apart from explicit weighted randomness, and independent from SpriteKit rendering.

The first implementation uses four base scenes (`idle`, `walk`, `stretch`, `sleep`) and three short reactions (`blink`, `happyJump`, `shyness`). A reaction can interrupt a base scene; it must not erase the base scene's plan.

## Model

The model distinguishes stable personality from changing state.

```text
Personality constants
    calmness     = 0.75
    playfulness  = 0.25
    shyness      = 0.45

Dynamic values, clamped to 0...100
    energy
    curiosity
    arousal
```

`arousal` means activity level, not positive or negative mood. Low arousal is quiet or sleepy; high arousal is active or playful. An emotion is derived from the values instead of being stored as an independent value.

```text
sleepy:   energy < 25
calm:     energy >= 25, arousal < 35, curiosity < 55
curious:  curiosity >= 60, energy >= 35
playful:  energy >= 60, arousal >= 60, random < playfulness
shy:      pointer nearby for >= 1.2 seconds, random < shyness
```

## Decision pipeline

The brain runs when a scene finishes or when it receives an external event.

```text
1. Receive event or scene-finished signal.
2. Apply high-priority event rules.
3. If no high-priority scene starts, apply state changes from the finished base scene.
4. Build the list of allowed candidate scenes.
5. Set the weight of each allowed scene.
6. Choose one candidate by weighted randomness.
7. Create an action plan for that scene and pass it to the animator.
8. Save enough context to resume after a short reaction.
```

Priority is fixed:

```text
drag start / drag end
    > click on the pet
    > edge reached
    > sleep or wake conditions
    > ordinary weighted choice
```

## Candidate conditions and weights

Before calculating weights, remove impossible candidates.

```text
sleep:
    available only if mouse has been still for 8–10 minutes,
    it is between 23:00 and 07:00,
    and energy < 45

shyness:
    available only if the pointer has been nearby for >= 1.2 seconds
    and its 90-second cooldown has ended

happyJump:
    starts directly from a click; it is not in the ordinary pool

walk:
    unavailable immediately after a completed walk;
    this guarantees a pause between walks
```

Initial weights:

```text
idleWeight =
    70
    + calmness * 20
    + (100 - arousal) * 0.20
    + (100 - energy) * 0.10

walkWeight =
    5
    + curiosity * 0.35
    + energy * 0.10
    + arousal * 0.10

stretchWeight =
    2
    + (100 - energy) * 0.16
    + (100 - arousal) * 0.08

sleepWeight =
    0 when sleep is unavailable;
    otherwise 20 + (100 - energy) * 0.40

shynessWeight =
    0 when shyness is unavailable;
    otherwise 15 + shyness * 30
```

Weighted random selection:

```text
totalWeight = sum(candidate.weight)
roll = random number in 0..<totalWeight

for candidate in a stable order:
    roll -= candidate.weight
    if roll <= 0:
        choose candidate
        stop
```

With a seeded random-number generator, the selection is reproducible in tests.

## State changes after base scenes

For v1, apply these deltas only after the scene finishes. This is easier to reason about than a permanent timer. If a scene is interrupted, later versions may apply a proportional delta.

```text
idle completed:
    energy +1
    curiosity +2
    arousal -3

walk completed:
    energy -3
    curiosity -12
    arousal +4

happyJump completed:
    energy -4
    arousal +12

sleep completed:
    energy +12
    arousal -10
```

Every value is clamped to `0...100`.

## Cooldowns and memory

```text
shyness:    90 seconds
happyJump:  2 seconds
stretch:    2 minutes
sleep:      unavailable until after a wake sequence
```

The brain also stores:

```text
lastBaseScene
lastDirection
InterruptedPlan
```

`InterruptedPlan` preserves a walk interrupted by `happyJump`.

```text
InterruptedPlan
    scene: walk
    direction: left or right
    targetX: final x-coordinate for the current short walk
```

After the jump finishes, the animator resumes this plan. Dragging and falling cancel the plan because the pet's position changed externally.

## Worked example: short walk

This example is the template for implementing other base scenes.

### 1. The previous scene ends

`idle` has lasted eight seconds. Its completion changes the dynamic state:

```text
before idle ends:
    energy = 63
    curiosity = 72
    arousal = 28

after idle ends:
    energy = 64
    curiosity = 74
    arousal = 25
```

### 2. High-priority checks

The brain checks, in order:

```text
Is the pet being dragged?             no
Was the pet just clicked?             no
Has it reached the screen edge?       no
Should it sleep?                      no
```

Nothing overrides the ordinary choice.

### 3. Filter candidates

Assume the previous base scene was `idle`, so `walk` is allowed. There is no nearby cursor and it is daytime.

```text
available:   idle, walk, stretch
unavailable: sleep, shyness
```

### 4. Calculate weights

With `calmness = 0.75`:

```text
idle = 70 + 0.75*20 + (100-25)*0.20 + (100-64)*0.10
     = 103.6

walk = 5 + 74*0.35 + 64*0.10 + 25*0.10
     = 39.8

stretch = 2 + (100-64)*0.16 + (100-25)*0.08
        = 13.76

total = 157.16
```

The resulting chance of a walk is `39.8 / 157.16`, approximately 25%. The pet usually rests, but a walk remains a meaningful possibility.

### 5. Pick a scene

Suppose the random roll is `125`.

```text
125 - idleWeight(103.6) = 21.4
21.4 - walkWeight(39.8) <= 0
```

The selected scene is `walk`.

### 6. Make a short-walk plan

The brain creates a plan; the SpriteKit layer only performs it.

```text
direction = randomly left or right
distance = random number from 96 to 280 points
targetX = clamp(currentX +/- distance, leftSafeEdge, rightSafeEdge)
duration = distance / walkSpeed
```

Use a constant `walkSpeed`, for example `26 points per second`, rather than a fixed left-edge-to-right-edge duration. This keeps short walks short and prevents a permanent cross-screen march.

If `targetX` lands within 48 points of an edge, the next event is `edgePause`, not an immediate reversal.

### 7. Persist interruption context

Before starting animation, save:

```text
InterruptedPlan(scene: walk, direction: direction, targetX: targetX)
```

If the user clicks the pet during this walk, the jump is played and then the remaining walk resumes toward `targetX`. If the user drags the pet, discard this plan and choose a new one after falling.

### 8. Finish and guarantee a pause

When the walk finishes:

```text
energy = max(0, energy - 3)
curiosity = max(0, curiosity - 12)
arousal = min(100, arousal + 4)
lastBaseScene = walk
```

On the immediately following ordinary choice, set `walkWeight = 0` because `lastBaseScene == walk`. The pet must choose `idle`, `stretch`, or another allowed reaction before it can walk again.

## Verification rules

Unit tests for the future brain should check:

```text
1. No candidate with weight 0 can be selected.
2. A completed walk makes the next ordinary walk unavailable.
3. A click creates happyJump before ordinary selection.
4. happyJump preserves and restores a walk plan.
5. Dragging cancels a saved walk plan.
6. Every dynamic value stays inside 0...100.
7. A seeded random generator produces the same choice for the same state.
```
