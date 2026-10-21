import SpriteKit

enum PetAnimations {
    static func idle(_ plan: PetBehavior.IdlePlan, frames: [SKTexture]) -> SKAction {
        var actions: [SKAction] = [
            .wait(forDuration: plan.initialWait)
        ]

        if plan.blink && !frames.isEmpty {
            actions.append(.animate(
                with: frames,
                timePerFrame: PetTuning.Idle.frameTime
            ))
        }

        actions.append(.wait(forDuration: plan.tailWait))
        return .sequence(actions)
    }

    /// Uses complete walk cycles so the sprite never stops mid-step.
    static func walk(_ plan: PetBehavior.WalkPlan, frames: [SKTexture], rest: SKTexture) -> SKAction {
        let face = SKAction.scaleX(
            to: plan.direction.xMultiplier * PetTuning.spriteScale,
            duration: 0
        )

        guard !frames.isEmpty else {
            return .sequence([
                face,
                .moveTo(x: plan.targetX, duration: plan.duration),
                .setTexture(rest, resize: false)
            ])
        }

        let cycleDuration = Double(frames.count) * PetTuning.Walk.frameTime
        let cycleCount = max(1, Int(ceil(plan.duration / cycleDuration)))
        let duration = Double(cycleCount) * cycleDuration

        let animation = SKAction.repeat(
            .animate(
                with: frames,
                timePerFrame: PetTuning.Walk.frameTime
            ),
            count: cycleCount
        )

        let movement = SKAction.moveTo(
            x: plan.targetX,
            duration: duration
        )

        return .sequence([
            face,
            .group([animation, movement]),
            .setTexture(rest, resize: false)
        ])
    }

    static func jump(frames: [SKTexture], rest: SKTexture) -> SKAction {
        guard !frames.isEmpty else { return .setTexture(rest, resize: false) }

        let frameTime = PetTuning.Jump.frameTime
        let duration = Double(frames.count) * frameTime

        let animation = SKAction.animate(
            with: frames,
            timePerFrame: frameTime
        )

        let movement = SKAction.sequence([
            .moveBy(x: 0, y: PetTuning.Jump.height, duration: duration / 2),
            .moveBy(x: 0, y: -PetTuning.Jump.height, duration: duration / 2)
        ])

        return .sequence([
            .group([animation, movement]),
            .setTexture(rest, resize: false)
        ])
    }
    
    static func stretch(frames: [SKTexture], rest: SKTexture) -> SKAction {
        guard !frames.isEmpty else { return .setTexture(rest, resize: false) }
        
        return .sequence([
            .animate(
                with: frames,
                timePerFrame: PetTuning.Stretch.frameTime
            ),
            .setTexture(rest, resize: false)
        ])
    }
}
