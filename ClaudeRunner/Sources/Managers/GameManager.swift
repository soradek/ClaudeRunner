import Foundation

class GameManager {
    static let shared = GameManager()

    var currentLevel: Int = 1
    var totalCoins: Int = 0
    var lives: Int = 3

    private init() {}

    func reset() {
        currentLevel = 1
        totalCoins = 0
        lives = 3
    }

    func nextLevel() {
        currentLevel += 1
        if currentLevel > 2 {
            currentLevel = 1
        }
    }
}
