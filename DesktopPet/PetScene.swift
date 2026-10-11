//
//  PetScene.swift
//  DesktopPet
//
//  Created by name space on 10/11/26.
//
import SpriteKit

final class PetScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = .darkGray
        
        func loadFrames(prefix: String, count: Int) -> [SKTexture] {
            (1...count).map { number in
                let name = String(format: "\(prefix)_%04d", number)
                let texture = SKTexture(imageNamed: name)
                texture.filteringMode = .nearest
                return texture
            }
        }
        
        let walkFrames = loadFrames(prefix: "walk", count: 8)
        let blinkFrames = loadFrames(prefix: "blink", count: 5)
        
        let pet = SKSpriteNode(
            texture: walkFrames[0]
        )
        pet.setScale(4)
        
        let leftEdge: CGFloat = 64
        let rightEdge = size.width - 64
        
        pet.position = CGPoint(x: leftEdge, y: size.height / 2)
        addChild(pet)
        
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
        
        pet.run(.repeatForever(routine))
    }
}
