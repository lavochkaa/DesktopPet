import SpriteKit

struct PetFrames {
    let walk: [SKTexture]
    let blink: [SKTexture]
    let jump: [SKTexture]
    let stretch: [SKTexture]
    let rest: SKTexture

    /// Loads every animation sequence before the scene starts running actions.
    static func load() -> PetFrames {
        let walk = loadFrames(prefix: "walk", count: 8)

        return PetFrames(
            walk: walk,
            blink: loadFrames(prefix: "blink", count: 5),
            jump: loadFrames(prefix: "jump", count: 10),
            stretch: loadFrames(prefix: "stretch", count: 10),
            rest: walk.last ?? loadTexture(named: "idle")
        )
    }

    private static func loadFrames(prefix: String, count: Int) -> [SKTexture] {
        guard count > 0 else { return [] }

        return (1...count).map { number in
            loadTexture(named: String(format: "\(prefix)_%04d", number))
        }
    }

    /// Pixel art uses nearest-neighbor filtering to keep its hard edges.
    private static func loadTexture(named name: String) -> SKTexture {
        let texture = SKTexture(imageNamed: name)
        texture.filteringMode = .nearest
        return texture
    }
}
