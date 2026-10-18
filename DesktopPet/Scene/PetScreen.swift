import AppKit
import SpriteKit

extension PetScene {
    /// Converts SpriteKit bounds to screen coordinates for AppKit hit testing.
    var petFrameOnScreen: NSRect? {
        guard let pet,
              let skView = view,
              let window = skView.window
        else { return nil }

        let frame = pet.calculateAccumulatedFrame()

        let firstPointInView = skView.convert(
            CGPoint(x: frame.minX, y: frame.minY), from: self
        )

        let secondPointInView = skView.convert(
            CGPoint(x: frame.maxX, y: frame.maxY), from: self
        )

        let firstPointOnScreen = window.convertPoint(
            toScreen: skView.convert(firstPointInView, to: nil)
        )

        let secondPointOnScreen = window.convertPoint(
            toScreen: skView.convert(secondPointInView, to: nil)
        )

        return NSRect(
            x: min(firstPointOnScreen.x, secondPointOnScreen.x),
            y: min(firstPointOnScreen.y, secondPointOnScreen.y),
            width: abs(secondPointOnScreen.x - firstPointOnScreen.x),
            height: abs(secondPointOnScreen.y - firstPointOnScreen.y)
        )
    }
}
