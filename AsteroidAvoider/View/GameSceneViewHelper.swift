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

struct GameSceneViewHelper {
    
    let scene: SKScene
    let player: SKSpriteNode
    
    func setupScene() {
        
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
        self.player.position.x = (-self.scene.size.width / 2) + self.player.size.width
        self.player.zPosition = 1
        self.scene.addChild(self.player)
    }
    
    func movePlayerFromAccelerometerData(_ data: CMAccelerometerData) {
        // X and Y are flipped because we're in landscape
        let changeX = CGFloat(data.acceleration.y) * 100
        let changeY = CGFloat(data.acceleration.x) * 100
        self.player.position.x -= changeX
        self.player.position.y += changeY
    }
    
}
