//
//  PetScene.swift
//  DesktopPet
//
//  Created by name space on 10/11/26.
//
import SpriteKit

final class PetScene: SKScene {
    private var pet: SKSpriteNode?
    private var normalRoutine: SKAction?
    private var jumpFrames: [SKTexture] = []
    
    private func loadFrames(prefix: String, count: Int) -> [SKTexture] {
        (1...count).map { number in
            let name = String(format: "\(prefix)_%04d", number)
            let texture = SKTexture(imageNamed: name)
            texture.filteringMode = .nearest
            return texture
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        
        guard let pet,
              pet.contains(location),
              pet.action(forKey: "happy") == nil
        else { return }
        
        pet.removeAction(forKey: "routine")
        
        let frameDuration = 1.0 / 16.0
        let jumpAnimation = SKAction.animate(
            with: jumpFrames,
            timePerFrame: frameDuration
        )
        
        let jumpDuration = Double(jumpFrames.count) * frameDuration
        let jumpMotion = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 40, duration: jumpDuration / 2),
            SKAction.moveBy(x: 0, y: -40, duration: jumpDuration / 2)
        ])
        
        let resumeRoutine = SKAction.run { [weak self, weak pet] in
            guard let self,
            let pet,
            let normalRoutine = self.normalRoutine
            else { return }
            
            pet.run(normalRoutine, withKey: "routine")
        }
        
        let happy = SKAction.sequence([
            SKAction.group([jumpAnimation, jumpMotion]),
            resumeRoutine
        ])
        
        pet.run(happy, withKey: "happy")
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        
        self.jumpFrames = loadFrames(prefix: "jump", count: 10)
        let walkFrames = loadFrames(prefix: "walk", count: 8)
        let blinkFrames = loadFrames(prefix: "blink", count: 5)
        
        let pet = SKSpriteNode(
            texture: walkFrames[0]
        )
        pet.name = "pet"
        pet.setScale(4)
        
        let leftEdge: CGFloat = 64
        let rightEdge = size.width - 64
        
        pet.position = CGPoint(x: leftEdge, y: pet.frame.height / 2)
        addChild(pet)
        self.pet = pet
        
        let walkCycle = SKAction.animate(
            with: walkFrames,
            timePerFrame: 1.0 / 8.0
        )
        let walkForTwoSeconds = SKAction.repeat(walkCycle, count: 2)
        
        let blink = SKAction.animate(
            with: blinkFrames,
            timePerFrame: 1.0 / 8.0
        )
        
        let walkRight = SKAction.group([
            SKAction.moveTo(x: rightEdge, duration: 2),
            walkForTwoSeconds
        ])
        
        let walkLeft = SKAction.group([
            SKAction.moveTo(x: leftEdge, duration: 2),
            walkForTwoSeconds
        ])
        
        let faceRight = SKAction.scaleX(to: 4, duration: 0)
        let faceLeft = SKAction.scaleX(to: -4, duration: 0)
        
        let routine = SKAction.sequence([
            faceRight,
            walkRight,
            SKAction.wait(forDuration: 1.5),
            blink,
            faceLeft,
            walkLeft,
            SKAction.wait(forDuration: 1.5),
            blink
        ])
        
        normalRoutine = .repeatForever(routine)
        pet.run(normalRoutine!, withKey: "routine")
    }
}
