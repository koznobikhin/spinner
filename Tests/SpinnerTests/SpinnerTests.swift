//
//  File.swift
//  
//
//  Created by Konstantin Oznobikhin on 03.09.2024.
//

@testable import Spinner
import XCTest

final class StreamMock: SpinnerStream {
    var showCursorCallCount = 0

    func write(string _: String, terminator _: String) {
    }
    
    func hideCursor() {
    }
    
    func showCursor() {
        showCursorCallCount += 1
    }
}

final class NowTests: XCTestCase {
    func testThatSpinnerShowsCursorOnStop() {
        let streamMock = StreamMock()
        let sut = Spinner(.dots, stream: streamMock)
        sut.stop()

        XCTAssertEqual(streamMock.showCursorCallCount, 1)
    }
}
