//
//  PetBehavior.swift
//  DesktopPet
//
//  Created by name space on 10/17/26.
//

import Foundation

enum PetBehavior {
    enum BaseScene {
        case idle
        case walk
        case stretch
        case sleep
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

    struct WalkPlan {
        let direction: Direction
        let targetX: CGFloat
        let duration: TimeInterval
    }

    struct Meters {
        var energy: Double = 60
        var curiosity: Double = 50
        var arousal: Double = 25

        mutating func applyCompletedWalk() {
            energy = max(0, energy - 3)
            curiosity = max(0, curiosity - 12)
            arousal = min(100, arousal + 4)
        }
    }
}
