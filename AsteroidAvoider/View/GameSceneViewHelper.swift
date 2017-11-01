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
    
    init(scene: SKScene, player: SKSpriteNode) {
        self.scene = scene
        self.player = player
    }
    
    func setupScene() {
        
        // Turn off gravity
        self.scene.physicsWorld.gravity = CGVector.zero
        
        // Create a border around the screen
        let enemyNode = SKSpriteNode(imageNamed: "asteroid")
        //TODO: make this border accurate
        let enemyWidthOrHeight: CGFloat = max(enemyNode.size.width, enemyNode.size.height)
        let halfScreenHeight: CGFloat = self.scene.size.height / 2
        let halfScreenWidth: CGFloat = self.scene.size.width / 2
        let borderFrame = CGRect(x: -halfScreenWidth - enemyWidthOrHeight, y: -halfScreenHeight - enemyWidthOrHeight, width: (halfScreenWidth * 2) + (enemyWidthOrHeight * 3), height: (halfScreenHeight * 2) + (enemyWidthOrHeight * 2))
        let borderBody = SKPhysicsBody(edgeLoopFrom: borderFrame)
        borderBody.friction = 0
        borderBody.categoryBitMask = PhysicsCategory.Border
        borderBody.contactTestBitMask = PhysicsCategory.Enemy | PhysicsCategory.Player
        self.scene.physicsBody = borderBody
        
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
        self.gameTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(GameSceneViewHelper.createEnemy), userInfo: nil, repeats: true)
        
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
    
    func createPlayer() {
        self.player.physicsBody = SKPhysicsBody(texture: self.player.texture!, size: self.player.size)
        self.player.physicsBody?.usesPreciseCollisionDetection = true
        self.player.physicsBody?.categoryBitMask = PhysicsCategory.Player
        self.player.physicsBody?.density = 1
        self.player.physicsBody?.contactTestBitMask = PhysicsCategory.Enemy
        self.player.position.x = (-self.scene.size.width / 2) + self.player.size.width
        self.player.zPosition = 1
        self.scene.addChild(self.player)
    }
    
    func movePlayerFromAccelerometerData(_ data: CMAccelerometerData) {
        // X and Y are flipped because we're in landscape
        let changeX = CGFloat(data.acceleration.y) * 10
        let changeY = CGFloat(data.acceleration.x) * 10
        self.player.position.x -= changeX
        self.player.position.y += changeY
    }
    
    @objc func createEnemy() {
        
        let screenHeight = self.scene.size.height / 2
        let screenWidth = self.scene.size.width / 2
        let randomDistribution = GKRandomDistribution(lowestValue: Int(-screenHeight), highestValue: Int(screenHeight))
        let randomSize = GKRandomDistribution(lowestValue: 3, highestValue: 7)
        
        let enemySprite = SKSpriteNode(imageNamed: "asteroid")
        
        // Get a position for the enemy
        var candidatePosition: CGPoint?
        for _ in 0..<10 {
            // Prevent enemies from being added on top of other enemies
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
        let spriteSize = max(enemySprite.size.width, enemySprite.size.height)
        enemySprite.physicsBody = SKPhysicsBody(circleOfRadius: spriteSize * scale)
        enemySprite.physicsBody?.categoryBitMask = PhysicsCategory.Enemy
        enemySprite.physicsBody?.velocity = CGVector(dx: CGFloat(-abs(randomDistribution.nextInt())), dy: 0)
        enemySprite.physicsBody?.density = 1
        enemySprite.physicsBody?.linearDamping = 0
        self.scene.addChild(enemySprite)
        
    }
    
    func locationIsEmpty(_ point: CGPoint) -> Bool {
        let nodes = self.scene.nodes(at: point)
        if let node = nodes.first, node.physicsBody?.categoryBitMask == PhysicsCategory.Enemy {
            return false
        }
        return true
    }
    
    func playerHit(_ node: SKNode) {
        if node.physicsBody?.categoryBitMask == PhysicsCategory.Enemy {
            // Player hit an enemy; make it bounce off the enemy and then get removed from the screen
            let nodeVelocity = node.physicsBody?.velocity ?? CGVector.zero
            let velocity = CGVector(dx: nodeVelocity.dx, dy: nodeVelocity.dy)
            let velocityAction = SKAction.applyImpulse(velocity, duration: 0.001)
            self.player.run(SKAction.sequence([velocityAction, SKAction.wait(forDuration: 1), SKAction.removeFromParent()]))
            self.playerWasHit = true
        }
        else if node.physicsBody?.categoryBitMask == PhysicsCategory.Border && self.playerWasHit {
            // The player was hit by an enemy and should then bounce off of any walls that were hit
            let playerVelocity = self.player.physicsBody?.velocity ?? CGVector.zero
            let velocity = CGVector(dx: playerVelocity.dx * -0.1, dy: playerVelocity.dy * -0.1)
            self.player.physicsBody?.applyImpulse(velocity)
        }
    }
    
    func enemyHit(_ node: SKNode) {
        // Remove asteroids that hit the border of the scene
        node.removeFromParent()
    }
    
}
