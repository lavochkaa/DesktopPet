import AppKit

final class MousePassthroughController {
    private weak var window: NSWindow?
    private weak var scene: PetScene?
    
    private var hoverTimer: Timer?

    init(window: NSWindow, scene: PetScene) {
        self.window = window
        self.scene = scene
        // Polling keeps click-through state current as the pet animates.
        let timer = Timer(
            timeInterval: 1.0 / 30.0,
            repeats: true
        ) { [weak self] _ in
            self?.updateMouseHandling()
        }
        RunLoop.main.add(timer, forMode: .common)
        hoverTimer = timer
    }

    deinit {
        hoverTimer?.invalidate()
    }

    private func updateMouseHandling() {
        guard let window = self.window,
              let scene = self.scene,
              let petFrame = scene.petFrameOnScreen
        else { return }
        // Pixel-art edges need a forgiving hit target.
        let clickableArea = petFrame.insetBy(dx: -8, dy: -8)
        let cursorIsOverPet = clickableArea.contains(NSEvent.mouseLocation)
        
        window.ignoresMouseEvents = !cursorIsOverPet
    }
}
