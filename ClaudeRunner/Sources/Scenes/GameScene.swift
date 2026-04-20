import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: – Nodes
    private var player: ClaudePlayerNode!
    private var cameraNode: SKCameraNode!
    private var worldNode: SKNode!
    private var hudNode: SKNode!

    // MARK: – HUD labels
    private var coinLabel: SKLabelNode!
    private var livesLabel: SKLabelNode!
    private var levelLabel: SKLabelNode!

    // MARK: – Control state
    private var isMovingLeft = false
    private var isMovingRight = false
    private var leftTouchId: UITouch?
    private var rightTouchId: UITouch?
    private var jumpTouchId: UITouch?

    // MARK: – Game state
    private let level: Int
    private var coins = 0
    private var isGameOver = false
    private var hasWon = false
    private var enemies: [EnemyNode] = []
    private var levelWidth: CGFloat = 3000

    // MARK: – Control buttons (positions in screen space)
    private let btnSize: CGFloat = 65
    private let btnAlpha: CGFloat = 0.55
    private var leftBtnRect = CGRect.zero
    private var rightBtnRect = CGRect.zero
    private var jumpBtnRect = CGRect.zero

    init(size: CGSize, level: Int) {
        self.level = level
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    // MARK: – Lifecycle

    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0, dy: -18)
        physicsWorld.contactDelegate = self

        worldNode = SKNode()
        addChild(worldNode)

        setupCamera()
        setupHUD()

        if level == 1 {
            buildLevel1()
        } else {
            buildLevel2()
        }

        setupControlButtons()
    }

    // MARK: – Camera

    private func setupCamera() {
        cameraNode = SKCameraNode()
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    // MARK: – HUD

    private func setupHUD() {
        hudNode = SKNode()
        cameraNode.addChild(hudNode)

        let coinBg = SKShapeNode(rectOf: CGSize(width: 130, height: 34), cornerRadius: 8)
        coinBg.fillColor = UIColor.black.withAlphaComponent(0.45)
        coinBg.strokeColor = .clear
        coinBg.position = CGPoint(x: -size.width / 2 + 75, y: size.height / 2 - 30)
        hudNode.addChild(coinBg)

        coinLabel = SKLabelNode(text: "🪙 0")
        coinLabel.fontName = "AvenirNext-Bold"
        coinLabel.fontSize = 18
        coinLabel.fontColor = UIColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 1.0)
        coinLabel.verticalAlignmentMode = .center
        coinLabel.position = coinBg.position
        hudNode.addChild(coinLabel)

        let livesBg = SKShapeNode(rectOf: CGSize(width: 110, height: 34), cornerRadius: 8)
        livesBg.fillColor = UIColor.black.withAlphaComponent(0.45)
        livesBg.strokeColor = .clear
        livesBg.position = CGPoint(x: -size.width / 2 + 75, y: size.height / 2 - 68)
        hudNode.addChild(livesBg)

        livesLabel = SKLabelNode(text: "❤️ \(GameManager.shared.lives)")
        livesLabel.fontName = "AvenirNext-Bold"
        livesLabel.fontSize = 18
        livesLabel.fontColor = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        livesLabel.verticalAlignmentMode = .center
        livesLabel.position = livesBg.position
        hudNode.addChild(livesLabel)

        levelLabel = SKLabelNode(text: "Poziom \(level)")
        levelLabel.fontName = "AvenirNext-Heavy"
        levelLabel.fontSize = 20
        levelLabel.fontColor = .white
        levelLabel.position = CGPoint(x: 0, y: size.height / 2 - 30)
        hudNode.addChild(levelLabel)
    }

    // MARK: – Level builders

    private func spawnPlayer(at pos: CGPoint) {
        player = ClaudePlayerNode()
        player.position = pos
        worldNode.addChild(player)
    }

    private func addGround(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat = 30,
                           color: UIColor = UIColor(red: 0.55, green: 0.35, blue: 0.15, alpha: 1.0)) {
        let node = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 4)
        node.fillColor = color
        node.strokeColor = color.withAlphaComponent(0.6)
        node.lineWidth = 2
        node.position = CGPoint(x: x + width / 2, y: y)
        node.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: width, height: height))
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.ground
        node.physicsBody?.contactTestBitMask = PhysicsCategory.player
        node.physicsBody?.collisionBitMask = PhysicsCategory.player | PhysicsCategory.enemy
        worldNode.addChild(node)

        // Grass top
        let grass = SKShapeNode(rectOf: CGSize(width: width, height: 8), cornerRadius: 3)
        grass.fillColor = UIColor(red: 0.3, green: 0.65, blue: 0.25, alpha: 1.0)
        grass.strokeColor = .clear
        grass.position = CGPoint(x: x + width / 2, y: y + height / 2 - 2)
        worldNode.addChild(grass)
    }

    private func addPlatform(x: CGFloat, y: CGFloat, width: CGFloat) {
        let node = SKShapeNode(rectOf: CGSize(width: width, height: 16), cornerRadius: 4)
        node.fillColor = UIColor(red: 0.6, green: 0.85, blue: 0.4, alpha: 1.0)
        node.strokeColor = UIColor(red: 0.3, green: 0.55, blue: 0.15, alpha: 1.0)
        node.lineWidth = 2
        node.position = CGPoint(x: x + width / 2, y: y)
        node.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: width, height: 16))
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.platform
        node.physicsBody?.contactTestBitMask = PhysicsCategory.player
        node.physicsBody?.collisionBitMask = PhysicsCategory.player | PhysicsCategory.enemy
        worldNode.addChild(node)
    }

    private func addCoin(at pos: CGPoint) {
        let coin = CoinNode()
        coin.position = pos
        worldNode.addChild(coin)
    }

    private func addEnemy(at pos: CGPoint, patrol: CGFloat = 120) {
        let enemy = EnemyNode()
        enemy.position = pos
        enemy.startX = pos.x
        enemy.patrolDistance = patrol
        enemies.append(enemy)
        worldNode.addChild(enemy)
    }

    private func addGoalFlag(at pos: CGPoint) {
        let pole = SKShapeNode(rectOf: CGSize(width: 6, height: 100))
        pole.fillColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
        pole.strokeColor = .clear
        pole.position = CGPoint(x: pos.x, y: pos.y + 50)
        worldNode.addChild(pole)

        let flag = SKShapeNode(path: {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: 3, y: 50))
            p.addLine(to: CGPoint(x: 40, y: 35))
            p.addLine(to: CGPoint(x: 3, y: 20))
            return p
        }())
        flag.fillColor = UIColor(red: 0.87, green: 0.48, blue: 0.27, alpha: 1.0)
        flag.strokeColor = .clear
        flag.position = CGPoint(x: pos.x, y: pos.y + 50)

        let wave = SKAction.sequence([
            SKAction.scaleX(to: 1.1, duration: 0.4),
            SKAction.scaleX(to: 0.9, duration: 0.4)
        ])
        flag.run(SKAction.repeatForever(wave))
        worldNode.addChild(flag)

        let goal = SKShapeNode(rectOf: CGSize(width: 30, height: 100))
        goal.fillColor = .clear
        goal.strokeColor = .clear
        goal.position = CGPoint(x: pos.x + 15, y: pos.y + 50)
        goal.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 30, height: 100))
        goal.physicsBody?.isDynamic = false
        goal.physicsBody?.categoryBitMask = PhysicsCategory.goal
        goal.physicsBody?.contactTestBitMask = PhysicsCategory.player
        goal.physicsBody?.collisionBitMask = PhysicsCategory.none
        worldNode.addChild(goal)
    }

    // MARK: – Level 1: Grassy Plains

    private func buildLevel1() {
        levelWidth = 3200
        backgroundColor = UIColor(red: 0.53, green: 0.81, blue: 0.98, alpha: 1.0)

        // Clouds
        for i in 0..<8 {
            addCloud(at: CGPoint(x: CGFloat(i) * 420 + 100, y: size.height * 0.78))
        }

        // Ground
        addGround(x: 0, y: 30, width: 700)
        addGround(x: 800, y: 30, width: 400)
        addGround(x: 1300, y: 30, width: 500)
        addGround(x: 1900, y: 30, width: 600)
        addGround(x: 2600, y: 30, width: 700)

        // Platforms
        addPlatform(x: 350, y: 170, width: 120)
        addPlatform(x: 550, y: 250, width: 100)
        addPlatform(x: 850, y: 190, width: 130)
        addPlatform(x: 1050, y: 280, width: 100)
        addPlatform(x: 1350, y: 160, width: 140)
        addPlatform(x: 1550, y: 260, width: 110)
        addPlatform(x: 1750, y: 180, width: 120)
        addPlatform(x: 2050, y: 220, width: 130)
        addPlatform(x: 2300, y: 310, width: 100)
        addPlatform(x: 2700, y: 190, width: 150)
        addPlatform(x: 2950, y: 280, width: 120)

        // Coins
        let coinPositions: [CGPoint] = [
            CGPoint(x: 200, y: 110), CGPoint(x: 260, y: 110), CGPoint(x: 320, y: 110),
            CGPoint(x: 380, y: 210), CGPoint(x: 430, y: 210),
            CGPoint(x: 570, y: 290), CGPoint(x: 620, y: 290),
            CGPoint(x: 870, y: 230), CGPoint(x: 920, y: 230),
            CGPoint(x: 1070, y: 320), CGPoint(x: 1120, y: 320),
            CGPoint(x: 1380, y: 200), CGPoint(x: 1430, y: 200),
            CGPoint(x: 1580, y: 300),
            CGPoint(x: 2100, y: 260), CGPoint(x: 2150, y: 260),
            CGPoint(x: 2730, y: 230), CGPoint(x: 2780, y: 230),
            CGPoint(x: 2990, y: 320), CGPoint(x: 3040, y: 320),
        ]
        coinPositions.forEach { addCoin(at: $0) }

        // Enemies
        addEnemy(at: CGPoint(x: 400, y: 55), patrol: 200)
        addEnemy(at: CGPoint(x: 950, y: 55), patrol: 150)
        addEnemy(at: CGPoint(x: 1500, y: 55), patrol: 180)
        addEnemy(at: CGPoint(x: 2100, y: 55), patrol: 200)
        addEnemy(at: CGPoint(x: 2800, y: 55), patrol: 160)

        // Player & goal
        spawnPlayer(at: CGPoint(x: 80, y: 120))
        addGoalFlag(at: CGPoint(x: 3120, y: 60))
        addDecoration(level: 1)
    }

    // MARK: – Level 2: Sky & Lava

    private func buildLevel2() {
        levelWidth = 3600
        backgroundColor = UIColor(red: 0.1, green: 0.05, blue: 0.25, alpha: 1.0)

        // Stars
        for _ in 0..<60 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...3))
            star.fillColor = .white
            star.strokeColor = .clear
            star.alpha = CGFloat.random(in: 0.4...1.0)
            star.position = CGPoint(x: CGFloat.random(in: 0...levelWidth),
                                    y: CGFloat.random(in: size.height * 0.3...size.height))
            worldNode.addChild(star)
            let twinkle = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.2, duration: Double.random(in: 0.5...1.5)),
                SKAction.fadeAlpha(to: 1.0, duration: Double.random(in: 0.5...1.5))
            ])
            star.run(SKAction.repeatForever(twinkle))
        }

        // Lava floor
        let lava = SKShapeNode(rectOf: CGSize(width: levelWidth + 200, height: 60))
        lava.fillColor = UIColor(red: 1.0, green: 0.3, blue: 0.0, alpha: 1.0)
        lava.strokeColor = UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)
        lava.lineWidth = 3
        lava.position = CGPoint(x: levelWidth / 2, y: 20)
        worldNode.addChild(lava)

        // Bubble lava particles
        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.colorize(with: UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0),
                              colorBlendFactor: 1, duration: 0.4),
            SKAction.colorize(with: UIColor(red: 1.0, green: 0.2, blue: 0.0, alpha: 1.0),
                              colorBlendFactor: 1, duration: 0.4)
        ]))
        lava.run(pulse)

        // Floating stone platforms (Mario castle-style)
        let stoneColor = UIColor(red: 0.45, green: 0.42, blue: 0.5, alpha: 1.0)
        let platformData: [(CGFloat, CGFloat, CGFloat)] = [
            (0,    50, 280), (380, 120, 100), (560, 200, 120), (760, 140, 100),
            (940,  220, 130), (1140, 300, 100), (1320, 180, 120), (1520, 260, 100),
            (1700, 160, 140), (1920, 240, 120), (2100, 330, 100), (2280, 180, 130),
            (2480, 260, 110), (2660, 160, 120), (2860, 240, 100), (3060, 180, 140),
            (3280, 100, 380)
        ]
        for (x, y, w) in platformData {
            addGround(x: x, y: y, width: w, height: 28, color: stoneColor)
        }

        // Coins – more vertical layout
        let coinPositions2: [CGPoint] = [
            CGPoint(x: 100, y: 130), CGPoint(x: 160, y: 130), CGPoint(x: 220, y: 130),
            CGPoint(x: 400, y: 200), CGPoint(x: 450, y: 200),
            CGPoint(x: 590, y: 280), CGPoint(x: 640, y: 280),
            CGPoint(x: 970, y: 300), CGPoint(x: 1020, y: 300),
            CGPoint(x: 1170, y: 380), CGPoint(x: 1220, y: 380),
            CGPoint(x: 1740, y: 240), CGPoint(x: 1790, y: 240),
            CGPoint(x: 1950, y: 320), CGPoint(x: 2000, y: 320),
            CGPoint(x: 2130, y: 410),
            CGPoint(x: 2510, y: 340), CGPoint(x: 2560, y: 340),
            CGPoint(x: 2890, y: 320), CGPoint(x: 2940, y: 320),
            CGPoint(x: 3100, y: 260), CGPoint(x: 3150, y: 260),
            CGPoint(x: 3310, y: 180), CGPoint(x: 3380, y: 180), CGPoint(x: 3450, y: 180),
        ]
        coinPositions2.forEach { addCoin(at: $0) }

        // More and harder enemies
        addEnemy(at: CGPoint(x: 150, y: 90), patrol: 120)
        addEnemy(at: CGPoint(x: 590, y: 225), patrol: 80)
        addEnemy(at: CGPoint(x: 980, y: 245), patrol: 90)
        addEnemy(at: CGPoint(x: 1330, y: 205), patrol: 80)
        addEnemy(at: CGPoint(x: 1720, y: 185), patrol: 100)
        addEnemy(at: CGPoint(x: 2290, y: 205), patrol: 90)
        addEnemy(at: CGPoint(x: 2680, y: 185), patrol: 100)
        addEnemy(at: CGPoint(x: 3090, y: 205), patrol: 120)
        addEnemy(at: CGPoint(x: 3350, y: 125), patrol: 140)

        spawnPlayer(at: CGPoint(x: 80, y: 150))
        addGoalFlag(at: CGPoint(x: 3560, y: 128))
        addDecoration(level: 2)
    }

    private func addCloud(at pos: CGPoint) {
        let cloud = SKNode()
        let positions = [CGPoint(x: 0, y: 0), CGPoint(x: 30, y: 12), CGPoint(x: -30, y: 6)]
        let radii: [CGFloat] = [28, 22, 20]
        for (i, p) in positions.enumerated() {
            let c = SKShapeNode(circleOfRadius: radii[i])
            c.fillColor = .white
            c.strokeColor = .clear
            c.alpha = 0.85
            c.position = p
            cloud.addChild(c)
        }
        cloud.position = pos
        worldNode.addChild(cloud)

        let drift = SKAction.sequence([
            SKAction.moveBy(x: 15, y: 0, duration: 3),
            SKAction.moveBy(x: -15, y: 0, duration: 3)
        ])
        cloud.run(SKAction.repeatForever(drift))
    }

    private func addDecoration(level: Int) {
        if level == 1 {
            // Trees
            for x in stride(from: CGFloat(100), to: levelWidth - 200, by: 280) {
                guard Int(x) % 560 < 280 else { continue }
                let tree = makeTree()
                tree.position = CGPoint(x: x, y: 60)
                worldNode.addChild(tree)
            }
        }
    }

    private func makeTree() -> SKNode {
        let t = SKNode()
        let trunk = SKShapeNode(rectOf: CGSize(width: 14, height: 30), cornerRadius: 2)
        trunk.fillColor = UIColor(red: 0.5, green: 0.3, blue: 0.1, alpha: 1.0)
        trunk.strokeColor = .clear
        trunk.position = CGPoint(x: 0, y: 15)
        t.addChild(trunk)

        let top = SKShapeNode(ellipseOf: CGSize(width: 44, height: 44))
        top.fillColor = UIColor(red: 0.2, green: 0.55, blue: 0.15, alpha: 1.0)
        top.strokeColor = .clear
        top.position = CGPoint(x: 0, y: 50)
        t.addChild(top)
        return t
    }

    // MARK: – Update

    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver, !hasWon else { return }

        let speed: CGFloat = 220
        var dx: CGFloat = 0
        if isMovingLeft { dx -= speed }
        if isMovingRight { dx += speed }

        player.physicsBody?.velocity = CGVector(dx: dx, dy: player.physicsBody?.velocity.dy ?? 0)
        player.update(deltaTime: 1.0 / 60.0, velocityX: dx)

        // Camera follows player horizontally, clamped
        let camX = max(size.width / 2,
                       min(player.position.x, levelWidth - size.width / 2))
        cameraNode.position = CGPoint(x: camX, y: size.height / 2)

        // Update enemies
        enemies.forEach { $0.update(deltaTime: 1.0 / 60.0) }

        // Fall off world
        if player.position.y < -80 {
            loseLife()
        }
    }

    // MARK: – Physics contact

    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA
        let b = contact.bodyB

        let categories = a.categoryBitMask | b.categoryBitMask

        // Get player body and "other" body to reason about positions, not normals
        let playerBody = a.categoryBitMask == PhysicsCategory.player ? a : b
        let otherBody  = a.categoryBitMask == PhysicsCategory.player ? b : a

        if categories == (PhysicsCategory.player | PhysicsCategory.ground) ||
           categories == (PhysicsCategory.player | PhysicsCategory.platform) {
            // Landing: player's feet above ground's top by some margin
            if let pNode = playerBody.node, let gNode = otherBody.node {
                if pNode.position.y > gNode.position.y {
                    player.isOnGround = true
                }
            }
        }

        if categories == (PhysicsCategory.player | PhysicsCategory.coin) {
            if let coin = otherBody.node as? CoinNode {
                coin.collect {
                    self.coins += 1
                    GameManager.shared.totalCoins += 1
                    self.coinLabel.text = "🪙 \(self.coins)"
                    self.showFloatingText("+1", at: coin.position, color: UIColor(red: 1.0, green: 0.85, blue: 0.1, alpha: 1.0))
                }
            }
        }

        if categories == (PhysicsCategory.player | PhysicsCategory.enemy) {
            if let enemy = otherBody.node as? EnemyNode {
                let playerVelY = player.physicsBody?.velocity.dy ?? 0
                // Stomping: player is falling and player's y is above enemy's y
                if playerVelY < -50 && player.position.y > enemy.position.y + 5 {
                    stompEnemy(enemy)
                } else if !player.isInvincible {
                    loseLife()
                }
            }
        }

        if categories == (PhysicsCategory.player | PhysicsCategory.goal) {
            levelComplete()
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if categories == (PhysicsCategory.player | PhysicsCategory.ground) ||
           categories == (PhysicsCategory.player | PhysicsCategory.platform) {
            // Player left a surface — will be set true again on next landing
            player.isOnGround = false
        }
    }

    private func stompEnemy(_ enemy: EnemyNode) {
        if let idx = enemies.firstIndex(of: enemy) {
            enemies.remove(at: idx)
        }
        enemy.squash {
            enemy.removeFromParent()
        }
        player.physicsBody?.velocity = CGVector(dx: player.physicsBody?.velocity.dx ?? 0, dy: 350)
        showFloatingText("Stomped!", at: enemy.position, color: UIColor(red: 1.0, green: 0.5, blue: 0.1, alpha: 1.0))
    }

    private func loseLife() {
        guard !isGameOver else { return }
        GameManager.shared.lives -= 1
        livesLabel.text = "❤️ \(GameManager.shared.lives)"

        if GameManager.shared.lives <= 0 {
            gameOver()
        } else {
            player.isInvincible = true
            player.flash()
            respawnPlayer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.player.isInvincible = false
            }
        }
    }

    private func respawnPlayer() {
        player.physicsBody?.velocity = .zero
        player.position = CGPoint(x: 80, y: 150)
        player.isOnGround = false
    }

    private func gameOver() {
        isGameOver = true
        showOverlay(title: "KONIEC GRY", subtitle: "Straciłeś wszystkie życia", btnText: "Spróbuj ponownie") {
            GameManager.shared.reset()
            let scene = GameScene(size: self.size, level: 1)
            scene.scaleMode = .aspectFill
            self.view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
        }
    }

    private func levelComplete() {
        guard !hasWon else { return }
        hasWon = true

        if level == 1 {
            showOverlay(title: "Poziom 1 Zaliczony!", subtitle: "🪙 Zebrałeś \(coins) monet", btnText: "Poziom 2 ▶") {
                GameManager.shared.nextLevel()
                let scene = GameScene(size: self.size, level: 2)
                scene.scaleMode = .aspectFill
                self.view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.6))
            }
        } else {
            showOverlay(title: "WYGRAŁEŚ! 🎉", subtitle: "Łącznie monet: \(GameManager.shared.totalCoins)", btnText: "Menu Główne") {
                GameManager.shared.reset()
                let scene = MenuScene(size: self.size)
                scene.scaleMode = .aspectFill
                self.view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.6))
            }
        }
    }

    private func showOverlay(title: String, subtitle: String, btnText: String, action: @escaping () -> Void) {
        let overlay = SKNode()
        cameraNode.addChild(overlay)

        let bg = SKShapeNode(rectOf: CGSize(width: 360, height: 200), cornerRadius: 18)
        bg.fillColor = UIColor.black.withAlphaComponent(0.75)
        bg.strokeColor = UIColor.white.withAlphaComponent(0.4)
        bg.lineWidth = 2
        overlay.addChild(bg)

        let t = SKLabelNode(text: title)
        t.fontName = "AvenirNext-Heavy"
        t.fontSize = 28
        t.fontColor = .white
        t.position = CGPoint(x: 0, y: 60)
        overlay.addChild(t)

        let s = SKLabelNode(text: subtitle)
        s.fontName = "AvenirNext-Medium"
        s.fontSize = 16
        s.fontColor = UIColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 1.0)
        s.position = CGPoint(x: 0, y: 20)
        overlay.addChild(s)

        let btn = SKShapeNode(rectOf: CGSize(width: 220, height: 48), cornerRadius: 10)
        btn.fillColor = UIColor(red: 0.87, green: 0.48, blue: 0.27, alpha: 1.0)
        btn.strokeColor = .clear
        btn.position = CGPoint(x: 0, y: -50)
        btn.name = "overlayBtn"
        overlay.addChild(btn)

        let btnLabel = SKLabelNode(text: btnText)
        btnLabel.fontName = "AvenirNext-Heavy"
        btnLabel.fontSize = 20
        btnLabel.fontColor = .white
        btnLabel.verticalAlignmentMode = .center
        btnLabel.position = btn.position
        btnLabel.name = "overlayBtn"
        overlay.addChild(btnLabel)

        overlay.name = "overlay"

        // Store action for tap handling
        userData = NSMutableDictionary()
        userData?["overlayAction"] = action
        userData?["overlay"] = overlay
    }

    private func showFloatingText(_ text: String, at pos: CGPoint, color: UIColor) {
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 20
        label.fontColor = color
        label.position = pos
        worldNode.addChild(label)

        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 0.7)
        let fade = SKAction.fadeOut(withDuration: 0.7)
        label.run(SKAction.group([moveUp, fade])) {
            label.removeFromParent()
        }
    }

    // MARK: – Control buttons

    private func setupControlButtons() {
        let margin: CGFloat = 20
        let bottom: CGFloat = -size.height / 2 + margin + btnSize / 2

        // Left button
        let leftBtn = makeControlBtn(text: "◀", name: "leftBtn")
        leftBtn.position = CGPoint(x: -size.width / 2 + margin + btnSize / 2, y: bottom)
        cameraNode.addChild(leftBtn)

        // Right button
        let rightBtn = makeControlBtn(text: "▶", name: "rightBtn")
        rightBtn.position = CGPoint(x: -size.width / 2 + margin + btnSize * 1.5 + 12, y: bottom)
        cameraNode.addChild(rightBtn)

        // Jump button
        let jumpBtn = makeControlBtn(text: "▲", name: "jumpBtn")
        jumpBtn.position = CGPoint(x: size.width / 2 - margin - btnSize / 2, y: bottom)
        cameraNode.addChild(jumpBtn)

        // Cache screen-space rects for hit testing
        let lx = -size.width / 2 + margin
        let ly = bottom - btnSize / 2
        leftBtnRect  = CGRect(x: lx, y: ly, width: btnSize, height: btnSize)
        rightBtnRect = CGRect(x: lx + btnSize + 12, y: ly, width: btnSize, height: btnSize)
        jumpBtnRect  = CGRect(x: size.width / 2 - margin - btnSize, y: ly, width: btnSize, height: btnSize)
    }

    private func makeControlBtn(text: String, name: String) -> SKNode {
        let node = SKNode()
        node.name = name

        let bg = SKShapeNode(circleOfRadius: btnSize / 2)
        bg.fillColor = UIColor.white.withAlphaComponent(btnAlpha)
        bg.strokeColor = UIColor.white.withAlphaComponent(0.7)
        bg.lineWidth = 2
        node.addChild(bg)

        let lbl = SKLabelNode(text: text)
        lbl.fontName = "AvenirNext-Heavy"
        lbl.fontSize = 26
        lbl.fontColor = UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 0.9)
        lbl.verticalAlignmentMode = .center
        node.addChild(lbl)

        return node
    }

    // Convert screen touch to camera-local coordinate
    private func cameraPoint(for touch: UITouch) -> CGPoint {
        let loc = touch.location(in: self)
        return CGPoint(x: loc.x - cameraNode.position.x, y: loc.y - cameraNode.position.y)
    }

    // MARK: – Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            handleTouchDown(touch)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let camPt = cameraPoint(for: touch)
            // If a control touch moved out of its zone, reassign
            if touch == leftTouchId && !leftBtnRect.contains(camPt) {
                if rightBtnRect.contains(camPt) {
                    isMovingLeft = false; isMovingRight = true
                    leftTouchId = nil; rightTouchId = touch
                }
            } else if touch == rightTouchId && !rightBtnRect.contains(camPt) {
                if leftBtnRect.contains(camPt) {
                    isMovingRight = false; isMovingLeft = true
                    rightTouchId = nil; leftTouchId = touch
                }
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { handleTouchUp(touch) }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { handleTouchUp(touch) }
    }

    private func handleTouchDown(_ touch: UITouch) {
        // Overlay button
        if let action = userData?["overlayAction"] as? () -> Void {
            let camPt = cameraPoint(for: touch)
            if let overlay = userData?["overlay"] as? SKNode {
                let btnPos = CGPoint(x: 0, y: -50)
                let btnRect = CGRect(x: btnPos.x - 110, y: btnPos.y - 24, width: 220, height: 48)
                if btnRect.contains(CGPoint(x: camPt.x - overlay.position.x,
                                           y: camPt.y - overlay.position.y)) {
                    overlay.removeFromParent()
                    userData?.removeAllObjects()
                    action()
                    return
                }
            }
        }

        let camPt = cameraPoint(for: touch)
        if leftBtnRect.contains(camPt) {
            isMovingLeft = true; leftTouchId = touch
        } else if rightBtnRect.contains(camPt) {
            isMovingRight = true; rightTouchId = touch
        } else if jumpBtnRect.contains(camPt) {
            jumpTouchId = touch
            player.jump()
        }
    }

    private func handleTouchUp(_ touch: UITouch) {
        if touch == leftTouchId  { isMovingLeft  = false; leftTouchId  = nil }
        if touch == rightTouchId { isMovingRight = false; rightTouchId = nil }
        if touch == jumpTouchId  { jumpTouchId  = nil }
    }
}
