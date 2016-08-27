//
//  LoggingTests.swift
//  LoggingTests
//
//  Created by 锋炜 刘 on 16/8/27.
//  Copyright © 2016年 kAzec. All rights reserved.
//

import XCTest
@testable import Logging

let logDirectory: NSString = {
    let directory = (NSTemporaryDirectory() as NSString)
        .stringByAppendingPathComponent("com.uncosmos.Logging.Tests")
    print("Using temporary directory \(directory) for tests.")
    return directory
}()

class LoggingTests: XCTestCase, Logging {
    
    var testMessage: String {
        return "A test message"
    }
    
    var _logger: Logger!
    var logger: Logger {
        return _logger
    }
    
    override func setUp() {
        super.setUp()
        _logger = Logger()
    }
    
    override func tearDown() {
        let _ = try? NSFileManager.defaultManager().removeItemAtPath(logDirectory as String)
        super.tearDown()
    }
    
    func sendMessage() {
        error(testMessage)
        logger.flush()
    }
    
    func testConsoleDestination() {
        let consoleDestination = ConsoleDestination()
        consoleDestination.theme = .classic()
        
        logger.destinations.append(consoleDestination)
        sendMessage()
    }
    
    func testASLDestination() {
        let aslDestination = ASLDestination()
        logger.destinations.append(aslDestination)
        sendMessage()
    }
    
    func testFileDestination() {
        let fileDestination = FileDestination(atPath:
            logDirectory.stringByAppendingPathComponent("com.uncosmos.Logging.Tests.log"))!
        
        fileDestination.theme = .classic()
        logger.destinations.append(fileDestination)
        sendMessage()
    }
    
    func testManagedFileDestinationAutoRotating() {
        let managedFileDestination = ManagedFileDestination(inDirectory:
            logDirectory.stringByAppendingPathComponent("Logs"))
        logger.destinations.append(managedFileDestination)
        sendMessage()
        
        XCTAssert(managedFileDestination.managedFileInfos.count == 1)
        
        NSThread.sleepForTimeInterval(0.250)
        managedFileDestination.rotatingInterval = 0.200
        sendMessage()
        XCTAssert(managedFileDestination.managedFileInfos.count == 2)
        
        managedFileDestination.maximumLogFileSize = UInt(1)
        sendMessage()
        XCTAssert(managedFileDestination.managedFileInfos.count == 3)
    }
    
    func testManagedFileDestinationAutoDeleting() {
        let managedFileDestination = ManagedFileDestination(inDirectory:
            logDirectory.stringByAppendingPathComponent("Logs"))
        logger.destinations.append(managedFileDestination)
        
        sendMessage() // 1
        NSThread.sleepForTimeInterval(0.100)
        managedFileDestination.rotate() // 2
        NSThread.sleepForTimeInterval(0.100)
        managedFileDestination.rotate() // 3
        NSThread.sleepForTimeInterval(0.100)
        managedFileDestination.rotate() // 4
        NSThread.sleepForTimeInterval(0.100)
        managedFileDestination.rotate() // 5
        
        XCTAssert(managedFileDestination.managedFileInfos.count == 5) // == 5
        
        managedFileDestination.maximumNumberOfLogFiles = 4
        XCTAssert(managedFileDestination.managedFileInfos.count == 4) // == 4
        
        NSThread.sleepForTimeInterval(0.250)
        managedFileDestination.expirationInterval = 0.200
        
        XCTAssert(managedFileDestination.managedFileInfos.count == 1) // == 1
        
        sendMessage() // 1, but will expire once rotated.
        managedFileDestination.rotate() // +1 -1 = 1
        sendMessage() // 1
        managedFileDestination.rotate() // 2
        sendMessage() // 2
        managedFileDestination.rotate() // 3
        sendMessage() // 3
        
        managedFileDestination.maximumLogFilesDiskSpace = 3 * 49
        
        XCTAssert(managedFileDestination.managedFileInfos.count == 3)
        managedFileDestination.maximumLogFilesDiskSpace -= 1
        XCTAssert(managedFileDestination.managedFileInfos.count == 2)
    }
}
