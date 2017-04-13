//
//  Extensions.swift
//  Logging
//
//  Created by 锋炜 刘 on 16/8/20.
//  Copyright © 2016年 kAzec. All rights reserved.
//

import Foundation

extension DispatchQueue {
    func sync() {
        let semaphore = DispatchSemaphore(value: 0)
        
        self.async {
            semaphore.signal()
        }
        
        let _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }
}

extension String {
    var UTF8String: [CChar] {
        return self.cString(using: String.Encoding.utf8)!
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
    
    static var identifier: String? {
        return Bundle.main.infoDictionary?[String(kCFBundleIdentifierKey)] as? String
    }
    
    static var name: String {
        return ProcessInfo.processInfo.processName
    }
    
    /// Path to "Logs" directory, "~/Library/Logs" for macOS and "\<Bundle\>/Library/Caches/Logs"
    /// for iOS, tvOS, watchOS
    static var logsDirectoryPath: String {
        #if os(OSX)
            let pathes = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
            return ((pathes.first ?? NSTemporaryDirectory()) as NSString).appendingPathComponent("Logs")
        #else // iOS, tvOS, watchOS
            let pathes = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
            let cacheDirectory = pathes[0]
            return (cacheDirectory as NSString).appendingPathComponent("Logs")
        #endif
    }
    
    static var ensuredLogsDirectoryPath: String {
        let directoryPath = logsDirectoryPath
        if !FileManager.default.fileExists(atPath: directoryPath) {
            do {
                try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Unable to create Application's Logs directory \(directoryPath).")
            }
        }
        
        return directoryPath
    }
}

extension FileManager {
    
    func isDirectory(_ directoryPath: String) -> Bool {
        var result: ObjCBool = false
        return fileExists(atPath: directoryPath, isDirectory: &result) && result.boolValue
    }
}
