import Cocoa
import SpriteKit

final class ViewController: NSViewController {
    private(set) var petScene: PetScene?
    private var mousePassthrough: MousePassthroughController?
    private var hasStarted = false
    
    override func viewWillAppear() {
        super.viewWillAppear()

        // The SpriteKit view receives its final size after the window appears.
        view.window?.alphaValue = 0
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        startPetIfNeeded()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = view as? SKView else { return }
        skView.allowsTransparency = true
    }

    private func startPetIfNeeded() {
        guard !hasStarted,
              let skView = view as? SKView,
              let window = view.window
        else {
            return
        }

        hasStarted = true

        if let screen = window.screen ?? NSScreen.main {
            // Keep this in sync with AppDelegate when the window changes screens.
            window.setFrame(screen.visibleFrame, display: true)
        }

        skView.layoutSubtreeIfNeeded()

        let scene = PetScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill

        petScene = scene
        skView.presentScene(petScene)

        mousePassthrough = MousePassthroughController(
            window: window,
            scene: scene
        )

        window.alphaValue = 1
    }

    override var representedObject: Any? {
        didSet {
        }
    }
}

