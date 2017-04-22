//
//  LogEntry.swift
//  Logging
//
//  Created by Fengwei Liu on 14/04/2017.
//  Copyright © 2017 kAzec. All rights reserved.
//

import Dispatch

extension DispatchQueue {
    
    func sync() {
        let semaphore = DispatchSemaphore(value: 0)
        
        self.async {
            semaphore.signal()
        }
        
        let _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }
}

import Darwin.C.time

extension Date {
    
    /// Format the date as "yyyy-MM-dd.HH-mm-ss-SSS".
    var logFileName: String {
        let epoch = timeIntervalSince1970
        var seconds = time_t(epoch)
        let milliseconds = Int((epoch - floor(epoch)) * 1000)
        
        var time = tm()
        localtime_r(&seconds, &time)
        return String(format: "%04d-%02d-%02d.%02d-%02d-%02d-%03d.log", time.tm_year + 1900, time.tm_mon + 1, time.tm_mday,
                      time.tm_hour, time.tm_min, time.tm_sec, milliseconds)
    }
}


#if os(iOS) || os(tvOS)
import UIKit
typealias App = UIApplication
#elseif os(watchOS)
import WatchKit
typealias App = WKExtension
#else
import AppKit
typealias App = NSApplication
#endif

extension App {
    
    static var loggingIdentifier: String {
        return Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName
    }
    
    /// URL to "Logs" directory, "~/Library/Logs/" for macOS and "\<Bundle\>/Library/Caches/Logs/"
    /// for iOS, tvOS, watchOS
    static var logsDirectory: URL {
        #if os(macOS) // macOS
            let libraryDirectoryPaths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
            let parentDirectory = URL(fileURLWithPath: libraryDirectoryPaths.first ?? NSTemporaryDirectory(),
                                      isDirectory: true)
            
            return parentDirectory.appendingPathComponent("Logs", isDirectory: false)
        #else // iOS, tvOS, watchOS
            let cachesDirectoryPaths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
            let cachesDirectory = URL(fileURLWithPath: cachesDirectoryPaths[0], isDirectory: true)
            return cachesDirectory.appendingPathComponent("Logs", isDirectory: false)
        #endif
    }
    
    static func makeLogsDirectory() -> URL {
        let logsDirectory = App.logsDirectory
        
        if !FileManager.default.fileExists(atPath: logsDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
            } catch {
                print("Unable to create application's \"Logs\" directory:\"\(logsDirectory.path)\".")
            }
        }
        
        return logsDirectory
    }
}
