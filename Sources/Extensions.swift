//
//  Extensions.swift
//  Logging
//
//  Created by 锋炜 刘 on 16/8/20.
//  Copyright © 2016年 kAzec. All rights reserved.
//

import Foundation

extension dispatch_queue_t {
    func sync() {
        let semaphore = dispatch_semaphore_create(0)
        
        dispatch_async(self) {
            dispatch_semaphore_signal(semaphore)
        }
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }
}

extension String {
    var UTF8String: [CChar] {
        return self.cStringUsingEncoding(NSUTF8StringEncoding)!
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
    class var identifier: String? {
        return NSBundle.mainBundle().infoDictionary?[String(kCFBundleIdentifierKey)] as? String
    }
    
    class var name: String {
        return NSProcessInfo.processInfo().processName
    }
    
    /// Path to "Logs" directory, "~/Library/Logs" for macOS and "\<Bundle\>/Library/Caches/Logs"
    /// for iOS, tvOS, watchOS
    class var logsDirectoryPath: String {
        #if os(OSX)
            let pathes = NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true)
            return (pathes.first ?? NSTemporaryDirectory() as NSString).stringByAppendingPathComponent("Logs")
        #else // iOS, tvOS, watchOS
            let pathes = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
            let cacheDirectory = pathes[0]
            return (cacheDirectory as NSString).stringByAppendingPathComponent("Logs")
        #endif
    }
    
    class var ensuredLogsDirectoryPath: String {
        let directoryPath = logsDirectoryPath
        if !NSFileManager.defaultManager().fileExistsAtPath(directoryPath) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(directoryPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Unable to create Application's Logs directory \(directoryPath).")
            }
        }
        
        return directoryPath
    }
}

extension NSFileManager {
    func isDirectory(directoryPath: String) -> Bool {
        var result: ObjCBool = false
        return fileExistsAtPath(directoryPath, isDirectory: &result) && result.boolValue
    }
}