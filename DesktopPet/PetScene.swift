//
//  PetScene.swift
//  DesktopPet
//
//  Created by name space on 10/11/26.
//
import SpriteKit

final class PetScene: SKScene {
    
    private var pet: SKSpriteNode?
    private var walkFrames: [SKTexture] = []
    private var blinkFrames: [SKTexture] = []
    
    private var meters = PetBehavior.Meters()
    private var lastBaseScene: PetBehavior.BaseScene?
    private var interruptedWalk: PetBehavior.WalkPlan?
    
    private var minWalkDistance: CGFloat = 96 // Минимум, который pet может пройти
    private var maxWalkDistance: CGFloat = 280 // Максимум, который pet может пройти
    private var walkSpeed: CGFloat = 26 // Скорость ходьбы, возможно добавлю смену скорости, при повышении/понижении энергии
    
    private var normalRoutine: SKAction?
    
    private var jumpFrames: [SKTexture] = []
    
    /*
     Очень долго думал, как быть с таким набором переменных, ведь оставлять magic values неправильно, но и на каждую заводить новую -
     не самый приятный для железа момент. Немного подумал и решил, что лучше просто положить их в static memory. Конечно больно на такое смотреть, но это пересчитывается раз в несколько десятков секунд, следовательно память сильно не используется ;(
     */
    private enum IdleTuning {
        static let blinkChance = 0.6 // Позже можно будет задать частоту моргания, например при низкой энергии
        static let blinkFrameTime: TimeInterval = 1.0 / 8.0
        static let initialWait: ClosedRange<TimeInterval> = 1.0...2.5
        static let waitAfterBlink: ClosedRange<TimeInterval> = 0...0.5
        static let waitWithoutBlink: ClosedRange<TimeInterval> = 0.5...1.0
    }
    
    /*
     MARK: - Pet On Screen
     Позже добавлю коментарии в этому блоку
    */
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
     MARK: - Idle
     Функция старта первоначального спрайта 'ожидания', с возможным морганием
    */
    private func startIdle() {
        guard let pet else { return }

        var idle: [SKAction] = [
            .wait(forDuration: .random(in: IdleTuning.initialWait))
        ]

        if !blinkFrames.isEmpty, Double.random(in: 0..<1) < IdleTuning.blinkChance {
            idle.append(.animate(with: blinkFrames, timePerFrame: IdleTuning.blinkFrameTime))
            idle.append(.wait(forDuration: .random(in: IdleTuning.waitAfterBlink)))
        } else {
            idle.append(.wait(forDuration: .random(in: IdleTuning.waitWithoutBlink)))
        }

        idle.append(.run { [weak self] in self?.finishIdle() })
        
        pet.run(.sequence(idle), withKey: "idle")
    }
    
    /*
     func finishIdle:
     Изменение весов, выбор следующего действия
    */
    private func finishIdle() {
        guard let pet else { return }
        
        // Меняем веса
        meters.applyCompletedIdle()
        
        // Запоминаем последне действие
        lastBaseScene = .idle
        
        chooseNextBaseScene()
    }
    
    /*
    Пока не используется, может быть позже верну, если на то нужна будет анимация
    
    private func startBlink() {
        guard let pet else { return }
        
        let frameDuration: TimeInterval = 1.0 / 8.0
        
        let blink = SKAction.sequence([
            SKAction.animate(with: blinkFrames, timePerFrame: frameDuration),
            SKAction.wait(forDuration: 1),
        ])
        
        pet.run(blink, withKey: "blink")
    }
    */
    
    /*
     MARK: - Walk
     Выбирает направление ходьбы, считает ее, время и затем отправляет
     */
    private func makeShortWalkPlan() -> PetBehavior.WalkPlan? {
        guard let pet else { return nil }
        
        // Получить безопасные границы экрана
        let petWidth = pet.calculateAccumulatedFrame().width
        let leftSafeEdge = petWidth / 2 + 8
        let rightSafeEdge = size.width - petWidth / 2 - 8
        
        let direction: PetBehavior.Direction
        
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
        return PetBehavior.WalkPlan(
            direction: direction,
            targetX: targetX,
            duration: duration
        )
    }
    
    /*
     func runWalk:
     Ничего не решает, просто запускает для WalkPlan
    */
    private func runWalk(_ plan: PetBehavior.WalkPlan) {
        guard let pet, !walkFrames.isEmpty else {
            return
        }
        
        // Повернуть спрайт
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
        
        // Запустить кадры ходьбы
        let walkAnimation = SKAction.repeat(
            walkCycle,
            count: cycleCount
        )
        // Передвинуть питомца в targetX
        let movement = SKAction.moveTo(
            x: plan.targetX,
            duration: synchronizedDuration
        )
        
        // Вызвать finishWalk()
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
            startIdle()          // Исправлена потенциальный stack overflow при chooseNextScene
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
        
        // Запоминает, что последней сценой была прогулка
        lastBaseScene = .walk
        interruptedWalk = nil
        
        // Передаёт управление функции выбора следующей сцены
        chooseNextBaseScene()
    }
    
    /*
     MARK: - Choose next scene
     Функция обработки и выбора возможных сценариев
    */
    private func chooseNextBaseScene() {
        switch lastBaseScene {
        case .idle:
            startShortWalk()
        case .walk, .stretch, .blink, .sleep, .none:
            startIdle() // Исправлен ожидаемый баг рекурсии при nil, позже разнесу по кейсам
        }
        
        // Здесь позже:
        // 1. проверка условий
        // 2. расчёт весов
        // 3. weighted random
        // 4. вызов startShortWalk(), startIdle(), startSleep() и так далее
    }
    
    /*
     MARK: - Load Frames
     Расчет и загрузка кадров по массивам, скорее всего для оптимизации памяти вынесу это отдельно, чтоб расчет был после каждого действия, но еще не знаю как правильно должно быть. Учимся ;)
    */
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
        blinkFrames = loadFrames(prefix: "blink", count: 5)
        
        let pet = SKSpriteNode(
            texture: walkFrames.last
        )
        pet.name = "pet"
        pet.setScale(4)
        
        let leftEdge: CGFloat = 64
        // let rightEdge = size.width - 64
        
        pet.position = CGPoint(x: leftEdge, y: pet.frame.height / 2)
        addChild(pet)
        self.pet = pet
        
        startIdle()
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
