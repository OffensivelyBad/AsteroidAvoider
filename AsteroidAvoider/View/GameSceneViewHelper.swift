//
//  GameSceneViewHelper.swift
//  AsteroidAvoider
//
//  Created by Shawn Roller on 10/27/17.
//  Copyright © 2017 Shawn Roller. All rights reserved.
//

import SpriteKit
import Foundation
import CoreMotion
import GameplayKit

class GameSceneViewHelper {
    
    private let testing = false
    
    let scene: SKScene
    let player: SKSpriteNode
    var gameTimer: Timer?
    var playerWasHit = false
    var cameraShouldFollowPlayer = false
    
    // Camera
    var camera: SKCameraNode?
    
    // Sounds
    let musicNode = SKAudioNode(fileNamed: "cyborg-ninja.mp3")
    
    // Scoring
    let scoreLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")
    var score = 0 {
        didSet {
            self.scoreLabel.text = "SCORE: \(score)"
        }
    }
    
    // Sizes
    var playerWidthOrHeight: CGFloat {
        return max(self.player.size.width, self.player.size.height)
    }
    
    init(scene: SKScene, player: SKSpriteNode) {
        self.scene = scene
        self.player = player
    }
    
}

// MARK: - Create nodes
extension GameSceneViewHelper {
    
    func setupScene() {
        
        // Setup the camera
        self.camera = SKCameraNode()
        self.scene.camera = self.camera
        if let cam = self.camera {
            self.scene.addChild(cam)
        }
        
        // Setup scoring
        setupScoring()
        
        // Begin playing music
        self.scene.addChild(self.musicNode)
        
        // Turn off gravity
        self.scene.physicsWorld.gravity = CGVector.zero
        
        // Create a border around the screen that will destroy the enemies when they leave the screen
        let enemyNode = SKSpriteNode(imageNamed: "asteroid")
        let enemyWidthOrHeight = max(enemyNode.size.width, enemyNode.size.height)
        let borderBody = createBorderForWidth(enemyWidthOrHeight)
        borderBody.categoryBitMask = PhysicsCategory.EnemyBorder
        borderBody.contactTestBitMask = PhysicsCategory.Enemy | PhysicsCategory.Energy
        borderBody.collisionBitMask = PhysicsCategory.Enemy | PhysicsCategory.Energy
        self.scene.physicsBody = borderBody
        
        // Create a border around the screen that will prevent the player from moving out of view
        let playerBorder = createBorderForWidth(self.playerWidthOrHeight)
        playerBorder.categoryBitMask = PhysicsCategory.PlayerBorder
        playerBorder.contactTestBitMask = PhysicsCategory.Player
        playerBorder.collisionBitMask = PhysicsCategory.Player
        let playerBorderNode = SKNode()
        playerBorderNode.physicsBody = playerBorder
        self.scene.addChild(playerBorderNode)
        
        // Create a background
        let background = SKSpriteNode(imageNamed: "space.jpg")
        background.zPosition = -1
        self.scene.addChild(background)
        
        // Add particles
        if let particles = SKEmitterNode(fileNamed: "SpaceDust") {
            particles.advanceSimulationTime(24)
            particles.position.x = self.scene.size.width / 2
            self.scene.addChild(particles)
        }
        
        // Add the player
        createPlayer()
        
        // Create the asteroids
        self.gameTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(GameSceneViewHelper.createGameNodes), userInfo: nil, repeats: true)
        
        // Add test nodes
        if self.testing {
            let halfScreenHeight = self.scene.size.height / 2
            let halfScreenWidth = self.scene.size.width / 2
            let topNode = SKSpriteNode(color: .white, size: CGSize(width: 100, height: 10))
            let bottomNode = SKSpriteNode(color: .red, size: CGSize(width: 100, height: 10))
            let leftNode = SKSpriteNode(color: .blue, size: CGSize(width: 10, height: 100))
            let rightNode = SKSpriteNode(color: .yellow, size: CGSize(width: 10, height: 100))
            topNode.position = CGPoint(x: -50, y: halfScreenHeight)
            bottomNode.position = CGPoint(x: -50, y: -halfScreenHeight)
            leftNode.position = CGPoint(x: -halfScreenWidth, y: -5)
            rightNode.position = CGPoint(x: halfScreenWidth, y: -5)
            self.scene.addChild(topNode)
            self.scene.addChild(bottomNode)
            self.scene.addChild(leftNode)
            self.scene.addChild(rightNode)
        }
        
    }
    
    func createBorderForWidth(_ width: CGFloat) -> SKPhysicsBody {
        
        let halfScreenHeight: CGFloat = self.scene.size.height / 2
        let halfScreenWidth: CGFloat = self.scene.size.width / 2
        let borderFrame = CGRect(x: -halfScreenWidth - width, y: -halfScreenHeight - width, width: (halfScreenWidth * 2) + (width * 3), height: (halfScreenHeight * 2) + (width * 2))
        let borderBody = SKPhysicsBody(edgeLoopFrom: borderFrame)
        borderBody.friction = 0
        return borderBody
        
    }
    
    func createPlayer() {
        self.player.physicsBody = SKPhysicsBody(texture: self.player.texture!, size: self.player.size)
        self.player.physicsBody?.usesPreciseCollisionDetection = true
        self.player.physicsBody?.categoryBitMask = PhysicsCategory.Player
        self.player.physicsBody?.collisionBitMask = PhysicsCategory.Enemy | PhysicsCategory.PlayerBorder
        self.player.physicsBody?.density = 1
        self.player.physicsBody?.contactTestBitMask = PhysicsCategory.Enemy
        self.player.position.x = (-self.scene.size.width / 2) + self.player.size.width
        self.player.zPosition = 1
        self.scene.addChild(self.player)
    }
    
    @objc func createGameNodes() {
        createEnemy()
        createEnergy()
    }
    
    func createEnemy() {
        
        let screenHeight = self.scene.size.height / 2
        let screenWidth = self.scene.size.width / 2
        let randomDistribution = GKRandomDistribution(lowestValue: Int(-screenHeight), highestValue: Int(screenHeight))
        let randomSize = GKRandomDistribution(lowestValue: 3, highestValue: 7)
        
        let enemySprite = SKSpriteNode(imageNamed: "asteroid")
        
        // Get a position for the enemy
        var candidatePosition: CGPoint?
        for _ in 0..<10 {
            // Prevent enemies from being added on top of other nodes
            let testPoint = CGPoint(x: screenWidth + enemySprite.size.width, y: CGFloat(randomDistribution.nextInt()))
            if locationIsEmpty(testPoint) {
                candidatePosition = testPoint
                break
            }
        }
        
        guard candidatePosition != nil else { return }
        let scale = CGFloat(randomSize.nextInt()) / 10
        enemySprite.position = candidatePosition!
        enemySprite.zPosition = 1
        enemySprite.setScale(scale)
        //let spriteSize = max(enemySprite.size.width, enemySprite.size.height)
        enemySprite.physicsBody = SKPhysicsBody(texture: enemySprite.texture ?? SKTexture(), size: enemySprite.size) // SKPhysicsBody(circleOfRadius: spriteSize * scale)
        enemySprite.physicsBody?.categoryBitMask = PhysicsCategory.Enemy
        enemySprite.physicsBody?.collisionBitMask = PhysicsCategory.Player
        enemySprite.physicsBody?.velocity = CGVector(dx: CGFloat(-abs(randomDistribution.nextInt())), dy: 0)
        enemySprite.physicsBody?.density = 1
        enemySprite.physicsBody?.linearDamping = 0
        self.scene.addChild(enemySprite)
        
    }
    
    func createEnergy() {
        
        let screenHeight = self.scene.size.height / 2
        let screenWidth = self.scene.size.width / 2
        let randomDistribution = GKRandomDistribution(lowestValue: Int(-screenHeight), highestValue: Int(screenHeight))
        
        let energySprite = SKSpriteNode(imageNamed: "energy")
        
        // Get a position for the energy
        var candidatePosition: CGPoint?
        for _ in 0..<10 {
            // Prevent energy from being added on top of other nodes
            let testPoint = CGPoint(x: screenWidth + energySprite.size.width, y: CGFloat(randomDistribution.nextInt()))
            if locationIsEmpty(testPoint) {
                candidatePosition = testPoint
                break
            }
        }
        
        guard candidatePosition != nil else { return }
        energySprite.position = candidatePosition!
        energySprite.zPosition = 1
        energySprite.physicsBody = SKPhysicsBody(texture: energySprite.texture ?? SKTexture(), size: energySprite.size)
        energySprite.physicsBody?.categoryBitMask = PhysicsCategory.Energy
        energySprite.physicsBody?.collisionBitMask = 0
        energySprite.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        energySprite.physicsBody?.velocity = CGVector(dx: CGFloat(-abs(randomDistribution.nextInt())), dy: 0)
        energySprite.physicsBody?.linearDamping = 0
        self.scene.addChild(energySprite)
        
    }
    
    func locationIsEmpty(_ point: CGPoint) -> Bool {
        let nodes = self.scene.nodes(at: point)
        if let node = nodes.first, node.physicsBody?.categoryBitMask == PhysicsCategory.Enemy || node.physicsBody?.categoryBitMask == PhysicsCategory.Energy {
            return false
        }
        return true
    }
    
}

// MARK: - Movement and collisions
extension GameSceneViewHelper {
    
    func movePlayerFromAccelerometerData(_ data: CMAccelerometerData) {
        // X and Y are flipped because we're in landscape
        let changeX = CGFloat(data.acceleration.y) * 10
        let changeY = CGFloat(data.acceleration.x) * 10
        self.player.position.x -= changeX
        self.player.position.y += changeY
    }
    
    func playerHit(_ node: SKNode) {
        if node.physicsBody?.categoryBitMask == PhysicsCategory.Enemy && !self.playerWasHit {
            
            // Stop the music
            self.musicNode.removeFromParent()
            
            // Zoom the camera on the player
            zoomCameraOnPlayer()
            
            // Player hit an enemy; make it bounce off the enemy and then get removed from the screen
            let nodeVelocity = node.physicsBody?.velocity ?? CGVector.zero
            let velocity = CGVector(dx: nodeVelocity.dx, dy: nodeVelocity.dy)
            let velocityAction = SKAction.applyImpulse(velocity, duration: 0.001)
            let playDeathSound = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false)
            let explosion = SKAction.run {
                if let particles = SKEmitterNode(fileNamed: "Explosion.sks") {
                    particles.position = self.player.position
                    particles.zPosition = 2
                    self.scene.addChild(particles)
                    self.player.removeFromParent()
                }
            }
            let gameOverBlock = SKAction.run {
                self.showGameOver()
            }
            self.player.run(SKAction.sequence([velocityAction, SKAction.wait(forDuration: 1), explosion, playDeathSound, gameOverBlock]))
            self.playerWasHit = true
        }
        else if node.physicsBody?.categoryBitMask == PhysicsCategory.PlayerBorder && self.playerWasHit {
            // The player was hit by an enemy and should then bounce off of any walls that were hit
            let playerVelocity = self.player.physicsBody?.velocity ?? CGVector.zero
            let velocity = CGVector(dx: playerVelocity.dx * -0.1, dy: playerVelocity.dy * -0.1)
            self.player.physicsBody?.applyImpulse(velocity)
        }
        else if node.physicsBody?.categoryBitMask == PhysicsCategory.Energy {
            self.score += 1
            node.removeFromParent()
        }
    }
    
    func enemyHit(_ node: SKNode) {
        // Remove asteroids that hit the border of the scene
        node.removeFromParent()
    }
    
}

// MARK: - Scoring
extension GameSceneViewHelper {
    
    func setupScoring() {
        
        self.scoreLabel.zPosition = 10
        self.scoreLabel.position.y = self.scene.size.height / 3
        self.scene.addChild(self.scoreLabel)
        self.score = 0
        
    }
    
    func showGameOver() {
        
        // Remove the now zoomed score label
        self.scoreLabel.removeFromParent()
        
        // Create a game over sprite
        let gameOver = SKSpriteNode(imageNamed: "gameOver-1")
        gameOver.zPosition = 10
        gameOver.setScale(0.001)
        self.scene.camera?.addChild(gameOver)
        
        let scoreBlock = SKAction.run {
            // Create a new score label
            let newScore = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")
            newScore.text = "Score: \(self.score)"
            newScore.position = CGPoint(x: 0, y: -gameOver.size.height)
            newScore.zPosition = 10
            self.scene.camera?.addChild(newScore)
        }
        
        gameOver.run(SKAction.sequence([SKAction.scale(to: 1, duration: 0.25), scoreBlock]))
        
    }
    
}

// MARK: - Camera
extension  GameSceneViewHelper {
    
    func updateCameraPosition() {
        guard self.cameraShouldFollowPlayer else { return }
        guard let cam = self.camera else { return }
        cam.position = self.player.position
    }
    
    func zoomCameraOnPlayer() {
        guard let cam = self.camera else { return }
        let scale = SKAction.scale(to: 0.25, duration: 0.2)
        let position = SKAction.move(to: self.player.position, duration: 0.2)
        let slowdown = SKAction.changePlaybackRate(by: 0.25, duration: 1)
        let runBlock = SKAction.run {
            self.cameraShouldFollowPlayer = true
        }
        cam.run(slowdown)
        cam.run(scale)
        let sequence = SKAction.sequence([position, runBlock])
        cam.run(sequence)
    }
    
}
