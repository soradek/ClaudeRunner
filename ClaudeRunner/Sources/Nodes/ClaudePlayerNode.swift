import SpriteKit

class ClaudePlayerNode: SKNode {

    private var body: SKShapeNode!
    private var head: SKShapeNode!
    private var leftEye: SKShapeNode!
    private var rightEye: SKShapeNode!
    private var mouth: SKShapeNode!
    private var leftArm: SKShapeNode!
    private var rightArm: SKShapeNode!
    private var leftLeg: SKShapeNode!
    private var rightLeg: SKShapeNode!
    private var walkTimer: TimeInterval = 0
    private var walkPhase: CGFloat = 0

    var isOnGround: Bool = false
    var isInvincible: Bool = false

    static let bodyWidth: CGFloat = 28
    static let bodyHeight: CGFloat = 44
    static let totalHeight: CGFloat = 60

    override init() {
        super.init()
        setupPhysics()
        drawCharacter()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPhysics() {
        let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: ClaudePlayerNode.bodyWidth,
                                                             height: ClaudePlayerNode.totalHeight))
        physicsBody.isDynamic = true
        physicsBody.allowsRotation = false
        physicsBody.restitution = 0
        physicsBody.friction = 0.5
        physicsBody.mass = 1.0
        physicsBody.categoryBitMask = PhysicsCategory.player
        physicsBody.contactTestBitMask = PhysicsCategory.ground | PhysicsCategory.enemy |
                                          PhysicsCategory.coin | PhysicsCategory.goal |
                                          PhysicsCategory.platform
        physicsBody.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.platform
        self.physicsBody = physicsBody
    }

    private func drawCharacter() {
        // Body (coral/orange-ish like Claude brand color)
        body = SKShapeNode(rectOf: CGSize(width: ClaudePlayerNode.bodyWidth, height: 28),
                           cornerRadius: 4)
        body.fillColor = UIColor(red: 0.87, green: 0.48, blue: 0.27, alpha: 1.0)
        body.strokeColor = UIColor(red: 0.6, green: 0.3, blue: 0.1, alpha: 1.0)
        body.lineWidth = 1.5
        body.position = CGPoint(x: 0, y: -8)
        addChild(body)

        // Head
        head = SKShapeNode(ellipseOf: CGSize(width: 26, height: 24))
        head.fillColor = UIColor(red: 0.95, green: 0.82, blue: 0.68, alpha: 1.0)
        head.strokeColor = UIColor(red: 0.7, green: 0.5, blue: 0.3, alpha: 1.0)
        head.lineWidth = 1.5
        head.position = CGPoint(x: 0, y: 18)
        addChild(head)

        // Left eye
        leftEye = SKShapeNode(ellipseOf: CGSize(width: 5, height: 6))
        leftEye.fillColor = UIColor(red: 0.15, green: 0.25, blue: 0.45, alpha: 1.0)
        leftEye.strokeColor = .clear
        leftEye.position = CGPoint(x: -5, y: 20)
        addChild(leftEye)

        // Right eye
        rightEye = SKShapeNode(ellipseOf: CGSize(width: 5, height: 6))
        rightEye.fillColor = UIColor(red: 0.15, green: 0.25, blue: 0.45, alpha: 1.0)
        rightEye.strokeColor = .clear
        rightEye.position = CGPoint(x: 5, y: 20)
        addChild(rightEye)

        // Smile
        let smilePath = CGMutablePath()
        smilePath.move(to: CGPoint(x: -5, y: 13))
        smilePath.addCurve(to: CGPoint(x: 5, y: 13),
                           control1: CGPoint(x: -3, y: 10),
                           control2: CGPoint(x: 3, y: 10))
        mouth = SKShapeNode(path: smilePath)
        mouth.strokeColor = UIColor(red: 0.5, green: 0.2, blue: 0.1, alpha: 1.0)
        mouth.lineWidth = 1.5
        addChild(mouth)

        // Arms
        leftArm = makeArm(flipped: false)
        leftArm.position = CGPoint(x: -17, y: -4)
        addChild(leftArm)

        rightArm = makeArm(flipped: true)
        rightArm.position = CGPoint(x: 17, y: -4)
        addChild(rightArm)

        // Legs
        leftLeg = makeLeg()
        leftLeg.position = CGPoint(x: -7, y: -26)
        addChild(leftLeg)

        rightLeg = makeLeg()
        rightLeg.position = CGPoint(x: 7, y: -26)
        addChild(rightLeg)
    }

    private func makeArm(flipped: Bool) -> SKShapeNode {
        let path = CGMutablePath()
        let dir: CGFloat = flipped ? 1 : -1
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: dir * 10, y: -8))
        let arm = SKShapeNode(path: path)
        arm.strokeColor = UIColor(red: 0.87, green: 0.48, blue: 0.27, alpha: 1.0)
        arm.lineWidth = 5
        arm.lineCap = .round
        return arm
    }

    private func makeLeg() -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 0, y: -14))
        let leg = SKShapeNode(path: path)
        leg.strokeColor = UIColor(red: 0.25, green: 0.35, blue: 0.55, alpha: 1.0)
        leg.lineWidth = 7
        leg.lineCap = .round
        return leg
    }

    func update(deltaTime: TimeInterval, velocityX: CGFloat) {
        walkTimer += deltaTime
        if abs(velocityX) > 10 {
            walkPhase += CGFloat(deltaTime) * 8
        }

        let legSwing = sin(walkPhase) * 6
        leftLeg.zRotation = legSwing * .pi / 32
        rightLeg.zRotation = -legSwing * .pi / 32

        let armSwing = sin(walkPhase) * 5
        leftArm.zRotation = armSwing * .pi / 32
        rightArm.zRotation = -armSwing * .pi / 32

        if velocityX < -5 {
            xScale = -1
        } else if velocityX > 5 {
            xScale = 1
        }
    }

    func flash() {
        let fadeOut = SKAction.fadeAlpha(to: 0.2, duration: 0.1)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        let flash = SKAction.sequence([fadeOut, fadeIn])
        let flashes = SKAction.repeat(flash, count: 6)
        run(flashes)
    }

    func jump() {
        guard isOnGround else { return }
        physicsBody?.velocity = CGVector(dx: physicsBody?.velocity.dx ?? 0, dy: 550)
        isOnGround = false

        let squash = SKAction.scaleX(to: 0.85, y: 1.15, duration: 0.05)
        let restore = SKAction.scaleX(to: 1.0, y: 1.0, duration: 0.1)
        run(SKAction.sequence([squash, restore]))
    }
}
