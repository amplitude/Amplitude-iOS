//
//  File.swift
//  
//
//  Created by Mayur Sharma on 22/11/19.
//

import XCTest
@testable import Amplitude

final class AmplitudeTests: XCTestCase {
    func testExample() {
        XCTAssertNotNil(Amplitude(), "Amplitude module error!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
