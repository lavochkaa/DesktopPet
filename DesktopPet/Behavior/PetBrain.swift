import Foundation

struct PetBrain {
    private(set) var meters = PetBehavior.Meters()
    private(set) var lastBaseScene: PetBehavior.BaseScene?
    private(set) var activeWalk: PetBehavior.WalkPlan?
    private(set) var lastStretchDate: Date?

    /// Applies a base scene's meter delta only after its animation completes.
    mutating func sceneFinished<R: RandomNumberGenerator>(
        _ scene: PetBehavior.BaseScene,
        x: CGFloat,
        bounds: ClosedRange<CGFloat>,
        time: Date,
        generator: inout R
    ) -> PetBehavior.Decision {
        switch scene {
        case .idle:
            meters.applyCompletedIdle()
        case .walk:
            meters.applyCompletedWalk()
            activeWalk = nil
        case .stretch:
            lastStretchDate = time
        case .sleep:
            break
        }

        lastBaseScene = scene
        return chooseNextScene(x: x, bounds: bounds, generator: &generator, time: time)
    }

    // TODO: Replace the temporary idle/walk cycle with the weighted pipeline from the pet-brain spec.
    mutating func chooseNextScene<R: RandomNumberGenerator>(
        x: CGFloat,
        bounds: ClosedRange<CGFloat>,
        generator: inout R,
        time: Date
    ) -> PetBehavior.Decision {
        switch lastBaseScene {
        case .idle, .stretch:
            // Check operation: .map will skipped nil and operation ?? will return true
            let stretchReady = lastStretchDate.map { time.timeIntervalSince($0) >= PetTuning.Stretch.cooldown } ?? true
            if stretchReady {
                return .stretch
            }
            if let plan = makeWalkPlan(x: x, bounds: bounds, generator: &generator) {
                activeWalk = plan
                return .walk(plan)
            }
            return .idle(makeIdlePlan(generator: &generator))
        case .walk, .sleep, .none:
            return .idle(makeIdlePlan(generator: &generator))
        }
    }

    func makeIdlePlan<R: RandomNumberGenerator>(generator: inout R) -> PetBehavior.IdlePlan {
        let blink = Double.random(in: 0...1, using: &generator) < PetTuning.Idle.blinkChance
        let tailRange = blink ? PetTuning.Idle.waitAfterBlink : PetTuning.Idle.waitWithoutBlink

        return PetBehavior.IdlePlan(
            initialWait: .random(in: PetTuning.Idle.initialWait, using: &generator),
            blink: blink,
            tailWait: .random(in: tailRange, using: &generator)
        )
    }

    func makeWalkPlan<R: RandomNumberGenerator>(
        x: CGFloat,
        bounds: ClosedRange<CGFloat>,
        generator: inout R
    ) -> PetBehavior.WalkPlan? {
        let minDistance = PetTuning.Walk.distance.lowerBound

        let direction: PetBehavior.Direction

        // Walking inward at an edge prevents off-screen or zero-length plans.
        if x <= bounds.lowerBound + minDistance {
            direction = .right
        } else if x >= bounds.upperBound - minDistance {
            direction = .left
        } else {
            direction = Bool.random(using: &generator) ? .left : .right
        }

        let requestedDistance = CGFloat.random(in: PetTuning.Walk.distance, using: &generator)

        let rawTargetX = x + direction.xMultiplier * requestedDistance
        let targetX = rawTargetX.clamped(to: bounds)

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

extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
