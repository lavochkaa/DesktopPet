//
//  SeededGenerator.swift
//  DesktopPetTests
//
//  Created by name space on 10/21/26.
//

import Foundation

struct SeededGenerator : RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    mutating func next() -> UInt64 {
        let A: UInt64 = 6364136223846793005
        let C: UInt64 = 1442695040888963407
        
        state = state &* A &+ C
        
        return state
    }
}
