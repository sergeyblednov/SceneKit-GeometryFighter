//
//  ShapeType.swift
//  GeometryFighter
//
//  Created by Sergey Blednov on 6/9/17.
//  Copyright © 2017 Pixacore. All rights reserved.
//

import Foundation

enum ShapeType: Int {
    
    case box = 0
    case sphere
    case pyramid
    case torus
    case capcule
    case cylinder
    case cone
    case tube
    
    
    static func random() -> ShapeType {
        let maxValue = tube.rawValue
        let rand = arc4random_uniform(UInt32(maxValue + 1))
        return ShapeType(rawValue: Int(rand))!
    }
}
