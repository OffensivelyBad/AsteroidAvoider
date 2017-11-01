//
//  GameScene.swift
//  AsteroidAvoider
//
//  Created by Shawn Roller on 10/23/17.
//  Copyright © 2017 Shawn Roller. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene {
    
    let kMotionControls = true
    var touchingPlayer = false
    
    var viewHelper: GameSceneViewHelper?
    let player = SKSpriteNode(imageNamed: "player-rocket.png")
    let motionManager = CMMotionManager()
    
    override func didMove(to view: SKView) {
        
        self.physicsWorld.contactDelegate = self
        
        // Add background, particles and player sprites
        self.viewHelper = GameSceneViewHelper(scene: self, player: self.player)
        self.viewHelper?.setupScene()
        
        // Enable motion controls if required
        if self.kMotionControls {
            self.motionManager.startAccelerometerUpdates()
        }
    }
    
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        
        // Destroy the view helper so it no longer holds a reference to the scene
        self.viewHelper = nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Implement touch controls if motion controls are off
        if !self.kMotionControls {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            let tappedNodes = self.nodes(at: location)
            if tappedNodes.contains(self.player) {
                self.touchingPlayer = true
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !self.kMotionControls {
            guard self.touchingPlayer, let touch = touches.first else { return }
            let location = touch.location(in: self)
            self.player.position = location
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchingPlayer = false
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        // If using motion controls, update the player position based on the gyroscope
        if let accelerometerData = self.motionManager.accelerometerData, self.kMotionControls {
            self.viewHelper?.movePlayerFromAccelerometerData(accelerometerData)
        }
        
    }
    
}

extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        guard let nodeA = contact.bodyA.node, let nodeB = contact.bodyB.node else { return }
        
        var firstNode: SKNode
        var secondNode: SKNode
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstNode = nodeA
            secondNode = nodeB
        }
        else {
            firstNode = nodeB
            secondNode = nodeA
        }
        
        guard let firstBody = firstNode.physicsBody, let secondBody = secondNode.physicsBody else { return }
        
        switch (firstBody.categoryBitMask, secondBody.categoryBitMask) {
        case (PhysicsCategory.Player, PhysicsCategory.Enemy), (PhysicsCategory.Player, PhysicsCategory.Border):
            self.viewHelper?.playerHit(secondNode)
        case (PhysicsCategory.Enemy, PhysicsCategory.Border):
            self.viewHelper?.enemyHit(firstNode)
        default:
            ()
        }
        
    }
    
}
