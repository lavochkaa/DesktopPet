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

    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        super.viewDidLoad()
        
        guard let skView = view as? SKView else { return }
        skView.allowsTransparency = true
    }
    
    func presentPetScene() {
        guard let skView = view as? SKView else { return }
        
        skView.layoutSubtreeIfNeeded()
        
        let scene = PetScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill
        
        petScene = scene
        skView.presentScene(petScene)
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

