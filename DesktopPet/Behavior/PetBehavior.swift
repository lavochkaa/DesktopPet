import Foundation

enum PetBehavior {
    enum BaseScene {
        case idle
        case walk
        case stretch
        case sleep
    }

    struct Meters {
        var energy: Double = 60
        var curiosity: Double = 50
        var arousal: Double = 25

        mutating func applyCompletedIdle() {
            energy = min(100, energy + 1)
            curiosity = min(100, curiosity + 2)
            arousal = max(0, arousal - 3)
        }

        mutating func applyCompletedWalk() {
            energy = max(0, energy - 3)
            curiosity = max(0, curiosity - 12)
            arousal = min(100, arousal + 4)
        }
    }

    enum Direction {
        case left
        case right

        var xMultiplier: CGFloat {
            switch self {
            case .left: return -1
            case .right: return 1
            }
        }
    }

    enum Decision {
        case idle(IdlePlan)
        case walk(WalkPlan)
    }

    struct IdlePlan {
        let initialWait: TimeInterval
        let blink: Bool
        let tailWait: TimeInterval
    }

    struct WalkPlan {
        let direction: Direction
        let targetX: CGFloat
        let duration: TimeInterval
    }
    // TODO: Add a jump plan to allow for future adjustments to length, height, etc.
    struct JumpPlan {}
}
