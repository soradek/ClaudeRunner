import SpriteKit

class EnemyNode: SKNode {

    private var bodyShape: SKShapeNode!
    private var leftEye: SKShapeNode!
    private var rightEye: SKShapeNode!
    private var direction: CGFloat = -1
    var patrolDistance: CGFloat = 120
    var startX: CGFloat = 0
    private var walkPhase: CGFloat = 0

    override init() {
        super.init()
        draw()
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    private func draw() {
        // Enemy is a red bug-like creature
        bodyShape = SKShapeNode(ellipseOf: CGSize(width: 32, height: 22))
        bodyShape.fillColor = UIColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 1.0)
        bodyShape.strokeColor = UIColor(red: 0.5, green: 0.05, blue: 0.05, alpha: 1.0)
        bodyShape.lineWidth = 2
        addChild(bodyShape)

        // Angry eyes
        leftEye = SKShapeNode(ellipseOf: CGSize(width: 7, height: 7))
        leftEye.fillColor = .white
        leftEye.strokeColor = .black
        leftEye.lineWidth = 1
        leftEye.position = CGPoint(x: -8, y: 4)
        addChild(leftEye)

        let leftPupil = SKShapeNode(ellipseOf: CGSize(width: 3, height: 3))
        leftPupil.fillColor = .black
        leftPupil.position = CGPoint(x: -8, y: 4)
        addChild(leftPupil)

        rightEye = SKShapeNode(ellipseOf: CGSize(width: 7, height: 7))
        rightEye.fillColor = .white
        rightEye.strokeColor = .black
        rightEye.lineWidth = 1
        rightEye.position = CGPoint(x: 8, y: 4)
        addChild(rightEye)

        let rightPupil = SKShapeNode(ellipseOf: CGSize(width: 3, height: 3))
        rightPupil.fillColor = .black
        rightPupil.position = CGPoint(x: 8, y: 4)
        addChild(rightPupil)

        // Legs
        for i in -1...1 {
            let leg = SKShapeNode(path: {
                let p = CGMutablePath()
                p.move(to: CGPoint(x: CGFloat(i) * 8, y: -10))
                p.addLine(to: CGPoint(x: CGFloat(i) * 12, y: -20))
                return p
            }())
            leg.strokeColor = UIColor(red: 0.5, green: 0.05, blue: 0.05, alpha: 1.0)
            leg.lineWidth = 3
            leg.lineCap = .round
            addChild(leg)
        }
    }

    private func setupPhysics() {
        let body = SKPhysicsBody(rectangleOf: CGSize(width: 30, height: 20))
        body.isDynamic = true
        body.allowsRotation = false
        body.restitution = 0
        body.categoryBitMask = PhysicsCategory.enemy
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.platform
        self.physicsBody = body
    }

    func update(deltaTime: TimeInterval) {
        guard let pb = physicsBody else { return }

        walkPhase += CGFloat(deltaTime) * 6

        let speed: CGFloat = 80
        pb.velocity = CGVector(dx: direction * speed, dy: pb.velocity.dy)

        if position.x < startX - patrolDistance {
            direction = 1
            xScale = -1
        } else if position.x > startX + patrolDistance {
            direction = -1
            xScale = 1
        }

        let bounce = abs(sin(walkPhase)) * 3
        bodyShape.position = CGPoint(x: 0, y: bounce)
    }

    func squash(completion: @escaping () -> Void) {
        let squashAction = SKAction.group([
            SKAction.scaleX(to: 1.5, duration: 0.1),
            SKAction.scaleY(to: 0.1, duration: 0.1)
        ])
        let fade = SKAction.fadeOut(withDuration: 0.15)
        run(SKAction.sequence([squashAction, fade, SKAction.run(completion)]))
    }
}
