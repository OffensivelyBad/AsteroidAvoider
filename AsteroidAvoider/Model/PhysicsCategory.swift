//
//  PhysicsCategory.swift
//  AsteroidAvoider
//
//  Created by Shawn Roller on 10/30/17.
//  Copyright © 2017 Shawn Roller. All rights reserved.
//

import Foundation

struct PhysicsCategory {
    static let Player: UInt32 = 0x1 << 0
    static let Enemy: UInt32 = 0x1 << 1
    static let Border: UInt32 = 0x1 << 2
}
