//
//  LogEntry.swift
//  Logging
//
//  Created by Fengwei Liu on 14/04/2017.
//  Copyright © 2017 kAzec. All rights reserved.
//

import XCTest
@testable import Logging

let logDirectory: URL = {
    let directoryPath = NSTemporaryDirectory()
    print("Using temporary directory \(directoryPath) for tests.")
    return URL(fileURLWithPath: directoryPath, isDirectory: true).appendingPathComponent("com.uncosmos.Logging.Tests")
}()

class LoggingTests: XCTestCase {
    
    var testMessage: String {
        return "A test message"
    }
    
    var _logger: Logger!
    var logger: Logger {
        return _logger
    }
    
    override func setUp() {
        super.setUp()
        _logger = Logger(minimumLevel: .debug, defaultFormatter: .concise)
        try! FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        Thread.sleep(forTimeInterval: 3)
        try! FileManager.default.removeItem(at: logDirectory)
        super.tearDown()
    }
    
    func sendMessage() {
        logger.error(testMessage)
        logger.synchronize()
    }
    
    func testASLDestination() {
        let aslDestination = ASLDestination()
        logger.addDestination(aslDestination)
        sendMessage()
    }
    
    func testOSLogDestination() {
        if #available(OSX 10.12, *) {
            let osLogDestination = OSLogDestination(category: "Test")
            logger.addDestination(osLogDestination)
            sendMessage()
        }
    }
    
    func testFileDestination() {
        let fileDestination = FileDestination(fileURL: logDirectory.appendingPathComponent("test.log"))
        logger.destinations.append(fileDestination)
        sendMessage()
    }
    
//    func testManagedFileDestinationAutoRotating() {
//        let managedFileDestination = ManagedFileDestination(inDirectory:
//            logDirectory.appendingPathComponent("Logs"))
//        logger.destinations.append(managedFileDestination)
//        sendMessage()
//        
//        XCTAssert(managedFileDestination.managedFileInfos.count == 1)
//        
//        Thread.sleep(forTimeInterval: 0.250)
//        managedFileDestination.rotatingInterval = 0.200
//        sendMessage()
//        XCTAssert(managedFileDestination.managedFileInfos.count == 2)
//        
//        managedFileDestination.maximumLogFileSize = UInt(1)
//        sendMessage()
//        XCTAssert(managedFileDestination.managedFileInfos.count == 3)
//    }
//    
//    func testManagedFileDestinationAutoDeleting() {
//        let managedFileDestination = ManagedFileDestination(inDirectory:
//            logDirectory.appendingPathComponent("Logs"))
//        logger.destinations.append(managedFileDestination)
//        
//        sendMessage() // 1
//        Thread.sleep(forTimeInterval: 0.100)
//        managedFileDestination.rotate() // 2
//        Thread.sleep(forTimeInterval: 0.100)
//        managedFileDestination.rotate() // 3
//        Thread.sleep(forTimeInterval: 0.100)
//        managedFileDestination.rotate() // 4
//        Thread.sleep(forTimeInterval: 0.100)
//        managedFileDestination.rotate() // 5
//        
//        XCTAssert(managedFileDestination.managedFileInfos.count == 5) // == 5
//        
//        managedFileDestination.maximumNumberOfLogFiles = 4
//        XCTAssert(managedFileDestination.managedFileInfos.count == 4) // == 4
//        
//        Thread.sleep(forTimeInterval: 0.250)
//        managedFileDestination.expirationInterval = 0.200
//        
//        XCTAssert(managedFileDestination.managedFileInfos.count == 1) // == 1
//        
//        sendMessage() // 1, but will expire once rotated.
//        managedFileDestination.rotate() // +1 -1 = 1
//        sendMessage() // 1
//        managedFileDestination.rotate() // 2
//        sendMessage() // 2
//        managedFileDestination.rotate() // 3
//        sendMessage() // 3
//        
//        managedFileDestination.maximumLogFilesDiskSpace = 3 * 49
//        
//        XCTAssert(managedFileDestination.managedFileInfos.count == 3)
//        managedFileDestination.maximumLogFilesDiskSpace -= 1
//        XCTAssert(managedFileDestination.managedFileInfos.count == 2)
//    }
}
