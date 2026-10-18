# DesktopPet

An autonomous pixel desktop pet for macOS, built with Swift, AppKit, and SpriteKit.

DesktopPet lives above the desktop, behaves calmly and curiously, occasionally plays, reacts to people, and stays out of the way during normal work.

This is a learning project exploring AppKit, SpriteKit, the macOS window server, state machines, animation, and the structure of a small Swift application.

## Vision

The pet is not meant to be decoration alone. Over time, it should grow into a local assistant without an LLM: it can notice safe system signals, develop a recognizable personality, and show understandable reactions.

The first priority is to make the pet feel alive on screen. Integrations with apps, email, calendars, and messengers come later.

The v1 personality is:

- curious;
- calm;
- occasionally playful;
- unobtrusive and non-blocking.

## Current features

- A transparent borderless overlay window above the desktop.
- Click-through behavior outside the pet's hit area.
- Pixel-perfect SpriteKit textures using `nearest` filtering.
- Idle behavior with a chance to blink.
- Short walks left and right within safe screen bounds.
- Movement synchronized to complete walk-animation cycles.
- A jump reaction when the pet is clicked.
- Base `energy`, `curiosity`, and `arousal` meters.

## Tech stack

- Swift 5
- AppKit + SpriteKit
- Xcode
- Aseprite / Piskel-compatible PNG animation exports
- `NSWindow`, `SKView`, `SKScene`, and `SKAction`

## Architecture

```text
AppDelegate
  └─ Configures the transparent overlay window.

ViewController
  └─ Creates PetScene once the window and SKView are ready.
  └─ Owns MousePassthroughController.

PetScene
  └─ SpriteKit layer: sprite, textures, SKAction, rendering, and input.

PetBehavior
  └─ Pure behavior data: states, direction, WalkPlan, and meters.

MousePassthroughController
  └─ Lets clicks pass through the window except near the pet.
```

The detailed pet-brain design is available in [docs/superpowers/specs/2026-10-16-pet-brain-design.md](docs/superpowers/specs/2026-10-16-pet-brain-design.md).

## Assets

Animation frames live in `Assets.xcassets` and follow this naming pattern:

```text
walk_0001 ... walk_0008
blink_0001 ... blink_0005
jump_0001 ... jump_0010
```

The pet is drawn at 32×32 px and scaled in the scene. Pixel-art textures must use:

```swift
texture.filteringMode = .nearest
```

## Behavior direction

Planned base scenes: `idle`, `walk`, `stretch`, and `sleep`.

Planned short reactions: `blink`, `happyJump`, and `shyness`.

The future decision pipeline is:

```text
event or scene completion
  → high-priority rules
  → available actions
  → weight calculation from meters and conditions
  → weighted random selection
  → action plan
  → SpriteKit animation
```

The meters are always clamped to `0...100`:

- `energy`: available stamina;
- `curiosity`: tendency to explore;
- `arousal`: activity level, not positive or negative mood.

## Build and run

Open `DesktopPet.xcodeproj` in Xcode and choose the `DesktopPet` scheme with the `My Mac` destination.

```bash
# Build
xcodebuild -project DesktopPet.xcodeproj -scheme DesktopPet -configuration Debug build

# Run tests when they are implemented
xcodebuild -project DesktopPet.xcodeproj -scheme DesktopPet test
```

In Xcode: `Cmd+B` builds, `Cmd+R` runs, and `Cmd+U` runs tests.

After behavior changes, manually verify the following:

1. The app launches without a white window.
2. The overlay remains transparent.
3. Clicks pass through outside the pet.
4. Clicking the pet triggers a reaction.
5. The pet walks in both directions, respects screen bounds, and stops only after a complete animation cycle.

## Out of scope for v1

- LLM features
- Sound and physics
- Settings
- Launch at login
- Multi-monitor support
- Integrations with email, calendars, Spotify, or messengers

## License

This project is licensed under the [MIT License](LICENSE).

## Git

Keep commits small and focused. Use English imperative commit messages, for example:

```text
Add blink animation
Extract pet behavior types
```

Do not commit `DerivedData`, per-user Xcode settings, credentials, or secrets.
