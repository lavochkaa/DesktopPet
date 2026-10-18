//
//  ViewController.swift
//  DesktopPet
//
//  Created by name space on 10/11/26.
//

import Cocoa
import SpriteKit

class ViewController: NSViewController {
    private(set) var petScene: PetScene?
    private var mousePassthrough: MousePassthroughController?
    private var hasStarted = false
    
    override func viewWillAppear() {
        super.viewWillAppear()

        view.window?.alphaValue = 0
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        startPetIfNeeded()
    }

    override func viewDidLoad() {
        // Do any additional setup after loading the view.
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
        // Update the view, if already loaded.
        }
    }


}

