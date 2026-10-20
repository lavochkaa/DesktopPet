//
//  DesktopPetTests.swift
//  DesktopPetTests
//
//  Created by name space on 10/11/26.
//

import Testing
@testable import DesktopPet

struct DesktopPetTests {

    @Test func seededGeneratorIsDeterministic() {
        var first = SeededGenerator(seed: 67)
        var second = SeededGenerator(seed: 67)
        
        #expect(first.next() == second.next())
    }

}
