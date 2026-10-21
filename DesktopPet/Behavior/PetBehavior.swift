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
            energy = (energy + 1).clamped(to: 0...100)
            curiosity = (curiosity + 2).clamped(to: 0...100)
            arousal = (arousal - 3).clamped(to: 0...100)
        }

        mutating func applyCompletedWalk() {
            energy = (energy - 3).clamped(to: 0...100)
            curiosity = (curiosity - 12).clamped(to: 0...100)
            arousal = (arousal + 4).clamped(to: 0...100)
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
        case stretch
        // case jump(JumpPlan)
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
    // struct JumpPlan {}
}

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
