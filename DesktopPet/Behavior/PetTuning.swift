import Foundation

nonisolated enum PetTuning {
    static let spriteScale: CGFloat = 4

    /// Points between the pet frame and the permitted walking edge.
    static let edgeMargin: CGFloat = 8

    /// Estimate: macOS does not expose the Dock's width, tuned by eye.
    static let dockInset: CGFloat = 100

    nonisolated enum Jump {
        static let height: CGFloat = 40
        static let frameTime: TimeInterval = 1.0 / 16.0
    }

    nonisolated enum Walk {
        /// Points per second.
        static let speed: CGFloat = 26
        static let minStep: CGFloat = 8
        static let frameTime: TimeInterval = 1.0 / 8.0
        static let distance: ClosedRange<CGFloat> = 96...280
    }

    nonisolated enum Idle {
        static let blinkChance = 0.6
        static let frameTime: TimeInterval = 1.0 / 8.0
        static let initialWait: ClosedRange<TimeInterval> = 1.0...2.5
        static let waitAfterBlink: ClosedRange<TimeInterval> = 0...0.5
        static let waitWithoutBlink: ClosedRange<TimeInterval> = 0.5...1.0
    }
    
    nonisolated enum Stretch {
        static let cooldown: TimeInterval = 120.0
        static let frameTime: TimeInterval = 1.0 / 8.0
    }
}
