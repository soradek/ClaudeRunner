import SpriteKit

class CoinNode: SKNode {

    override init() {
        super.init()
        draw()
        setupPhysics()
        animate()
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    private func draw() {
        let circle = SKShapeNode(circleOfRadius: 9)
        circle.fillColor = UIColor(red: 1.0, green: 0.85, blue: 0.1, alpha: 1.0)
        circle.strokeColor = UIColor(red: 0.8, green: 0.6, blue: 0.0, alpha: 1.0)
        circle.lineWidth = 2

        let label = SKLabelNode(text: "C")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 10
        label.fontColor = UIColor(red: 0.8, green: 0.6, blue: 0.0, alpha: 1.0)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center

        addChild(circle)
        addChild(label)
    }

    private func setupPhysics() {
        let body = SKPhysicsBody(circleOfRadius: 9)
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.coin
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = PhysicsCategory.none
        self.physicsBody = body
    }

    private func animate() {
        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 5, duration: 0.5),
            SKAction.moveBy(x: 0, y: -5, duration: 0.5)
        ])
        run(SKAction.repeatForever(bob))

        let spin = SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 2))
        run(spin)
    }

    func collect(completion: @escaping () -> Void) {
        let pop = SKAction.group([
            SKAction.scale(to: 1.6, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.2)
        ])
        let up = SKAction.moveBy(x: 0, y: 30, duration: 0.2)
        run(SKAction.group([pop, up])) {
            completion()
            self.removeFromParent()
        }
    }
}
