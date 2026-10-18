import SpriteKit

final class PetScene: SKScene {
    // MARK: - State

    private(set) var pet: SKSpriteNode?

    private lazy var frames = PetFrames.load()
    private var brain = PetBrain()
    
    private enum ActionKey {
        static let scene = "scene"
        static let jump = "jump"
    }
    
    // MARK: - Geometry

    private var spawnPoint: CGPoint {
        guard let pet else { return .zero }

        let x = (walkBounds.lowerBound + walkBounds.upperBound) / 2

        return CGPoint(
            x: x,
            y: pet.calculateAccumulatedFrame().height / 2
        )
    }

    /// Uses SpriteKit layout so the decision engine stays independent from rendering.
    private var walkBounds: ClosedRange<CGFloat> {
        guard let pet else { return 0...0 }

        let halfWidth = pet.calculateAccumulatedFrame().width / 2
        let inset = PetTuning.dockInset + halfWidth + PetTuning.edgeMargin

        guard size.width > inset * 2 else {
            return pet.position.x...pet.position.x
        }
        return inset...(size.width - inset)
    }

    // MARK: - Running scenes

    private func perform(_ decision: PetBehavior.Decision) {
        guard let pet else { return }

        let scene: PetBehavior.BaseScene
        let action: SKAction

        switch decision {
        case .idle(let plan):
            scene = .idle
            action = PetAnimations.idle(plan, frames: frames.blink)

        case .walk(let plan):
            scene = .walk
            action = PetAnimations.walk(plan, frames: frames.walk, rest: frames.rest)
        }

        pet.run(.sequence(
            [action, .run { [weak self] in self?.finish(scene) }]),
                withKey: ActionKey.scene
        )
    }

    private func finish(_ scene: PetBehavior.BaseScene) {
        guard let pet else { return }

        let decision = brain.sceneFinished(
            scene,
            x: pet.position.x,
            bounds: walkBounds
        )

        perform(decision)
    }

    private func resumeAfterJump() {
        guard let pet else { return }

        let decision = brain.chooseNextScene(
            x: pet.position.x,
            bounds: walkBounds
        )

        perform(decision)
    }

    // MARK: - Input

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        guard let pet,
                pet.contains(location),
              pet.action(forKey: ActionKey.jump) == nil
        else {
            return
        }
        pet.removeAction(forKey: ActionKey.scene)
        let jump = PetAnimations.jump(
            frames: frames.jump,
            rest: frames.rest
        )

        pet.run(.sequence([
            jump, .run { [weak self] in self?.resumeAfterJump() }]),
                withKey: ActionKey.jump
        )
    }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = .clear

        let pet = SKSpriteNode(
            texture: frames.rest
        )

        pet.name = "pet"
        pet.setScale(PetTuning.spriteScale)

        addChild(pet)
        self.pet = pet

        pet.position = spawnPoint

        let decision = brain.chooseNextScene(
            x: pet.position.x,
            bounds: walkBounds
        )

        perform(decision)
    }
}
