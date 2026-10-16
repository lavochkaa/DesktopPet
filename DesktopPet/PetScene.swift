//
//  PetScene.swift
//  DesktopPet
//
//  Created by name space on 10/11/26.
//
import SpriteKit

final class PetScene: SKScene {
    // Позже перенесу все в нормальную архитектуру
    private enum BaseScene {
        case idle
        case walk
        case stretch
        case sleep
    }
    
    private enum Direction {
        case left
        case right
        
        var xMultiplier: CGFloat {
            switch self {
                case .left: return -1
                case .right: return 1
            }
        }
    }
    
    private struct WalkPlan {
        let direction: Direction
        let targetX: CGFloat
        let duration: TimeInterval
    }
    
    private struct PetMeters {
        var energy: Double = 60
        var curiosity: Double = 50
        var arousal: Double = 25
        
        mutating func applyCompletedWalk() {
            energy = max(0, energy - 3)
            curiosity = max(0, curiosity - 12)
            arousal = min(100, arousal + 4)
        }
    }
    
    private var pet: SKSpriteNode?
    private var walkFrames: [SKTexture] = []
    
    private var meters = PetMeters()
    private var lastBaseScene: BaseScene?
    private var interruptedWalk: WalkPlan?
    
    private var minWalkDistance: CGFloat = 96
    private var maxWalkDistance: CGFloat = 280
    private var walkSpeed: CGFloat = 26
    
    private var normalRoutine: SKAction?
    
    private var jumpFrames: [SKTexture] = []
    
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
    
    /*
     func startIdle:
     Функция старта первоначального спрайта 'ожидания'
    */
    private func startIdle() {
        guard let pet else { return }
        
        // Собирает анимацию, перед этим подождав 3 секунды
        let idle = SKAction.sequence([
            SKAction.wait(forDuration: 3),
            SKAction.run { [weak self] in
                self?.lastBaseScene = .idle
                self?.startShortWalk()
            }
        ])
        
        // Запускаем анимацию
        pet.run(idle, withKey: "idle")
    }
    
    /*
     func makeShortWalkPlan:
     Выбирает направление ходьбы, считает ее, время и затем отправляет
     */
    private func makeShortWalkPlan() -> WalkPlan? {
        guard let pet else { return nil }
        
        // Получить безопасные границы экрана
        let petWidth = pet.calculateAccumulatedFrame().width
        let leftSafeEdge = petWidth / 2 + 8
        let rightSafeEdge = size.width - petWidth / 2 - 8
        
        let direction: Direction
        
        // Выбрать направление
        // У края всегда идти внутрь, а не пытаться выйти за экран
        if pet.position.x <= leftSafeEdge + minWalkDistance {
            direction = .right
        } else if pet.position.x >= rightSafeEdge - minWalkDistance {
            direction = .left
        } else {
            // В центре — выбрать направление случайно
            direction = Bool.random() ? .left : .right
        }
        
        // Выбрать короткую дистанцию 96...280
        let requestedDistance = CGFloat.random(in: minWalkDistance...maxWalkDistance)
        
        // Ограничить конечную позицию границами
        let rawTargetX = pet.position.x + direction.xMultiplier * requestedDistance
        let targetX = min(max(rawTargetX, leftSafeEdge), rightSafeEdge)
        
        let actualDistance = abs(pet.position.x - targetX)
        guard actualDistance >= 8 else { return nil }
        
        // Посчитать длительность по формуле: duration = distance / speed
        let duration = TimeInterval(actualDistance / walkSpeed)
        
        // Вернуть готовый WalkPlan.
        return WalkPlan(
            direction: direction,
            targetX: targetX,
            duration: duration
        )
    }
    
    /*
     func runWalk -> ничего не решает, просто запускает для:
     WalkPlan
         → повернуть спрайт
         → запустить кадры ходьбы
         → передвинуть питомца в targetX
         → вызвать finishWalk()
     */
    private func runWalk(_ plan: WalkPlan) {
        guard let pet, !walkFrames.isEmpty else {
            return
        }

        let spriteScale = abs(pet.xScale)
        pet.xScale = plan.direction.xMultiplier * spriteScale

        let frameDuration: TimeInterval = 1.0 / 8.0

        let walkCycle = SKAction.animate(
            with: walkFrames,
            timePerFrame: frameDuration
        )

        let cycleDuration = Double(walkFrames.count) * frameDuration

        let cycleCount = max(
            1,
            Int(ceil(plan.duration / cycleDuration))
        )

        let synchronizedDuration = TimeInterval(cycleCount) * cycleDuration

        let walkAnimation = SKAction.repeat(
            walkCycle,
            count: cycleCount
        )

        let movement = SKAction.moveTo(
            x: plan.targetX,
            duration: synchronizedDuration
        )

        let walk = SKAction.sequence([
            SKAction.group([movement, walkAnimation]),
            SKAction.run { [weak self] in
                self?.finishWalk()
            }
        ])

        pet.run(walk, withKey: "walk")
    }
    
    /*
     func startShortWalk:
     Является связующей функцией
     */
    private func startShortWalk() {
        guard let plan = makeShortWalkPlan() else {
            chooseNextBaseScene()
            return
        }
        interruptedWalk = plan
        
        runWalk(plan)
    }
    
    /*
     func finishWalk:
     Останавливает прогулку, пересчитывает веса и запоминает последнее действие
    */
    private func finishWalk() {
        guard let pet else { return }
        // Убирает ошибку разрыва кадров (пока визуально)
        pet.texture = walkFrames.last
        
        // Уменьшает энергию и любопытство
        meters.applyCompletedWalk()
        
        // Запоминает, что последней сценой была прогулка.
        lastBaseScene = .walk
        interruptedWalk = nil
        
        // Передаёт управление функции выбора следующей сцены
        chooseNextBaseScene()
    }
    
    private func chooseNextBaseScene() {
        if lastBaseScene == .walk {
            startIdle()
            return
        }
        
        // Здесь позже:
        // 1. проверка условий
        // 2. расчёт весов
        // 3. weighted random
        // 4. вызов startShortWalk(), startIdle(), startSleep() и так далее
    }
    
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
        walkFrames = loadFrames(prefix: "walk", count: 8)
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
        
        startShortWalk()
        /*
        Временно закоментированно

        let walkCycle = SKAction.animate(
            with: walkFrames,
            timePerFrame: 1.0 / 8.0
        )
        let walkForTwoSeconds = SKAction.repeat(walkCycle, count: 15)
        
        let blink = SKAction.animate(
            with: blinkFrames,
            timePerFrame: 1.0 / 8.0
        )
        
        let walkRight = SKAction.group([
            SKAction.moveTo(x: rightEdge, duration: 15),
            walkForTwoSeconds
        ])
        
        let walkLeft = SKAction.group([
            SKAction.moveTo(x: leftEdge, duration: 15),
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
        */
    }
}
