import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = self.view as? SKView else { return }
        skView.showsFPS = false
        skView.showsNodeCount = false
        skView.ignoresSiblingOrder = true

        let scene = MenuScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func loadView() {
        self.view = SKView(frame: UIScreen.main.bounds)
    }
}
