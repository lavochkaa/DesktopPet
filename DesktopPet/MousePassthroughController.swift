//
//  MousePassthroughController.swift
//  DesktopPet
//
//  Created by name space on 10/12/26.
//

import AppKit

final class MousePassthroughController {
    private weak var window: NSWindow?
    private weak var scene: PetScene?
    
    private var hoverTimer: Timer?
    
    init(window: NSWindow, scene: PetScene) {
        self.window = window
        self.scene = scene
        
        hoverTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 30.0,
            repeats: true,
        ) { [weak self] _ in
            self?.updateMouseHandling()
        }
    }
    
    deinit {
        hoverTimer?.invalidate()
    }
    
    private func updateMouseHandling() {
        guard let realWindow = self.window,
              let realScene = self.scene,
              let petFrame = realScene.petFrameOnScreen
        else { return }
        
        let clickableArea = petFrame.insetBy(dx: -8, dy: -8)
        let cursorIsOverPet = clickableArea.contains(NSEvent.mouseLocation)
        
        realWindow.ignoresMouseEvents = !cursorIsOverPet
    }
}
