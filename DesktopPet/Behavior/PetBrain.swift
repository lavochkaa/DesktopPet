import Foundation

struct PetBrain {
    private(set) var meters = PetBehavior.Meters()
    private(set) var lastBaseScene: PetBehavior.BaseScene?
    private(set) var activeWalk: PetBehavior.WalkPlan?

    /// Applies a base scene's meter delta only after its animation completes.
    mutating func sceneFinished(_ scene: PetBehavior.BaseScene, x: CGFloat, bounds: ClosedRange<CGFloat>) -> PetBehavior.Decision {
        switch scene {
        case .idle:
            meters.applyCompletedIdle()
        case .walk:
            meters.applyCompletedWalk()
            activeWalk = nil
        case .stretch, .sleep:
            break
        }

        lastBaseScene = scene
        return chooseNextScene(x: x, bounds: bounds)
    }

    // TODO: Replace the temporary idle/walk cycle with the weighted pipeline from the pet-brain spec.
    mutating func chooseNextScene(x: CGFloat, bounds: ClosedRange<CGFloat>) -> PetBehavior.Decision {
        switch lastBaseScene {
        case .idle:
            if let plan = makeWalkPlan(x: x, bounds: bounds) {
                activeWalk = plan
                return .walk(plan)
            }
            return .idle(makeIdlePlan())
        case .walk, .stretch, .sleep, .none:
            return .idle(makeIdlePlan())
        }
    }

    func makeIdlePlan() -> PetBehavior.IdlePlan {
        let blink = Double.random(in: 0...1) < PetTuning.Idle.blinkChance
        let tailRange = blink ? PetTuning.Idle.waitAfterBlink : PetTuning.Idle.waitWithoutBlink

        return PetBehavior.IdlePlan(
            initialWait: .random(in: PetTuning.Idle.initialWait),
            blink: blink,
            tailWait: .random(in: tailRange)
        )
    }

    func makeWalkPlan(x: CGFloat, bounds: ClosedRange<CGFloat>) -> PetBehavior.WalkPlan? {
        let minDistance = PetTuning.Walk.distance.lowerBound

        let direction: PetBehavior.Direction

        // Walking inward at an edge prevents off-screen or zero-length plans.
        if x <= bounds.lowerBound + minDistance {
            direction = .right
        } else if x >= bounds.upperBound - minDistance {
            direction = .left
        } else {
            direction = Bool.random() ? .left : .right
        }

        let requestedDistance = CGFloat.random(in: PetTuning.Walk.distance)

        let rawTargetX = x + direction.xMultiplier * requestedDistance
        let targetX = min(max(rawTargetX, bounds.lowerBound), bounds.upperBound)

        let actualDistance = abs(x - targetX)

        // Avoid running an animation for movement the user cannot perceive.
        guard actualDistance >= PetTuning.Walk.minStep else { return nil }

        let duration = TimeInterval(actualDistance / PetTuning.Walk.speed)

        return PetBehavior.WalkPlan(
            direction: direction,
            targetX: targetX,
            duration: duration
        )
    }
}
