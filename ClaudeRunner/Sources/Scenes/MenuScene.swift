import SpriteKit

class MenuScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
        setupBackground()
        setupUI()
    }

    private func setupBackground() {
        // Clouds
        for i in 0..<4 {
            let cloud = makeCloud()
            cloud.position = CGPoint(x: CGFloat(i) * 220 + 80, y: size.height * 0.75)
            addChild(cloud)
        }

        // Ground strip
        let ground = SKShapeNode(rectOf: CGSize(width: size.width, height: 80))
        ground.fillColor = UIColor(red: 0.3, green: 0.65, blue: 0.25, alpha: 1.0)
        ground.strokeColor = .clear
        ground.position = CGPoint(x: size.width / 2, y: 40)
        addChild(ground)
    }

    private func makeCloud() -> SKNode {
        let cloud = SKNode()
        let positions = [CGPoint(x: 0, y: 0), CGPoint(x: 25, y: 10), CGPoint(x: -25, y: 5)]
        let radii: [CGFloat] = [22, 18, 16]
        for (i, pos) in positions.enumerated() {
            let c = SKShapeNode(circleOfRadius: radii[i])
            c.fillColor = .white
            c.strokeColor = .clear
            c.alpha = 0.9
            c.position = pos
            cloud.addChild(c)
        }
        return cloud
    }

    private func setupUI() {
        // Title
        let title = SKLabelNode(text: "CLAUDE RUNNER")
        title.fontName = "AvenirNext-Heavy"
        title.fontSize = 42
        title.fontColor = UIColor(red: 0.87, green: 0.48, blue: 0.27, alpha: 1.0)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.65)
        addChild(title)

        let shadow = SKLabelNode(text: "CLAUDE RUNNER")
        shadow.fontName = "AvenirNext-Heavy"
        shadow.fontSize = 42
        shadow.fontColor = UIColor(red: 0.4, green: 0.2, blue: 0.05, alpha: 0.5)
        shadow.position = CGPoint(x: size.width / 2 + 3, y: size.height * 0.65 - 3)
        insertChild(shadow, at: 0)

        let subtitle = SKLabelNode(text: "A platformer adventure")
        subtitle.fontName = "AvenirNext-Medium"
        subtitle.fontSize = 18
        subtitle.fontColor = .white
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.55)
        addChild(subtitle)

        // Mini Claude character on menu
        let player = ClaudePlayerNode()
        player.position = CGPoint(x: size.width / 2, y: size.height * 0.38)
        addChild(player)

        let wave = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 8, duration: 0.5),
            SKAction.moveBy(x: 0, y: -8, duration: 0.5)
        ])
        player.run(SKAction.repeatForever(wave))

        // Play button
        let playBtn = makeButton(text: "▶  GRAJ", width: 200, height: 55)
        playBtn.position = CGPoint(x: size.width / 2, y: size.height * 0.22)
        playBtn.name = "playBtn"
        addChild(playBtn)

        // Blink prompt
        let tap = SKLabelNode(text: "Dotknij aby zagrać!")
        tap.fontName = "AvenirNext-Medium"
        tap.fontSize = 14
        tap.fontColor = UIColor.white.withAlphaComponent(0.8)
        tap.position = CGPoint(x: size.width / 2, y: size.height * 0.1)
        addChild(tap)
        tap.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.7),
            SKAction.fadeIn(withDuration: 0.7)
        ])))
    }

    private func makeButton(text: String, width: CGFloat, height: CGFloat) -> SKNode {
        let btn = SKNode()
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 12)
        bg.fillColor = UIColor(red: 0.87, green: 0.48, blue: 0.27, alpha: 1.0)
        bg.strokeColor = UIColor(red: 0.5, green: 0.25, blue: 0.05, alpha: 1.0)
        bg.lineWidth = 3
        btn.addChild(bg)

        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 22
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        btn.addChild(label)
        return btn
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let nodes = nodes(at: loc)
        if nodes.contains(where: { $0.name == "playBtn" }) || true {
            startGame()
        }
    }

    private func startGame() {
        GameManager.shared.reset()
        let scene = GameScene(size: size, level: 1)
        scene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 0.6)
        view?.presentScene(scene, transition: transition)
    }
}
