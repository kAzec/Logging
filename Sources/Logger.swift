//
//  LogEntry.swift
//  Logging
//
//  Created by Fengwei Liu on 14/04/2017.
//  Copyright © 2017 kAzec. All rights reserved.
//

import Foundation

public class Logger {
    
    /// A Boolean value that determines whether the logger is enabled.
    public var isEnabled = true
    
    /// The minimum priority level. Only messages that have priority level higher than this will be logged.
    public var minimumLevel: LogPriorityLevel
    
    /// The default log formatter of the logger. This formatter will be used if a destination doesn't have one.
    public let defaultFormatter: LogFormatter
    
    /// The dispatch group used to synchronize the destinations.
    let group = DispatchGroup()
    
    /// The default dispatch queue of the logger. This queue is used to serialize all incoming messages and, if a
    /// destination doesn't have a queue for itself, will be used as a substitute.
    let queue = DispatchQueue(label: "com.uncosmos.Logging.default")
    
    /// The destinations of the logger.
    var destinations = [LogDestination]()

    /// Create and returns a new logger with minimum log priority level and default log formatter specified.
    ///
    /// - parameter minimumLevel:   The minimum level that determines whether a log message should be logged.
    /// - parameter formatter:      The log formatter of the logger.
    /// - parameter destinations:   The destinations of the logger.
    ///
    /// - returns: The new logger.
    public init(minimumLevel: LogPriorityLevel, defaultFormatter: LogFormatter) {
        self.minimumLevel = minimumLevel
        self.defaultFormatter = defaultFormatter
    }
    
    /// Add a new destination to the logger, adding the same destination again will have no effect.
    public func addDestination(_ destination: LogDestination) {
        queue.async {
            // Make sure that the same desitnation instance will not be added twice.
            guard self.destinations.index(where: { $0 === destination }) == nil else {
                return
            }
            
            if let queue = destination.queue {
                queue.async(execute: destination.initialize)
            } else {
                destination.initialize()
            }
        }
    }
    
    /// Remove the given destination from the logger.
    public func removeDestination(_ destination: LogDestination) {
        queue.async {
            guard let indexOfDestination = self.destinations.index(where: { $0 === destination }) else {
                return
            }
            
            let destination = self.destinations.remove(at: indexOfDestination)
            Logger.notifyDidRemoveDestination(destination)
        }
    }
    
    /// Remove all destinations from the logger.
    public func removeAllDestinations() {
        queue.async {
            self.destinations.removeAll()
            self.destinations.forEach(Logger.notifyDidRemoveDestination(_:))
        }
    }
    
    /// Wait until all asynchronous logging activities in each destinations are finished.
    public func synchronize() {
        queue.sync {
            for destination in destinations {
                if let queue = destination.queue {
                    queue.async(group: group, execute: DispatchWorkItem(block: destination.synchronize))
                } else {
                    destination.synchronize()
                }
            }
            
            group.wait()
        }
    }
    
    /// Wait until all asynchronous logging activities in the given destination are finished.
    public func synchronizeDestination(_ destination: LogDestination) {
        queue.sync {
            guard self.destinations.index(where: { $0 === destination }) != nil else {
                return
            }
            
            if let queue = destination.queue {
                queue.sync(execute: destination.synchronize)
            } else {
                destination.synchronize()
            }
        }
    }
    
    deinit {
        // Release resources used by destinations.
        let destinations = self.destinations
        queue.async {
            destinations.forEach(Logger.notifyDidRemoveDestination(_:))
        }
    }
    
    fileprivate func log(_ level: LogPriorityLevel, message: (() -> String), function: String, file: String, line: Int) {
        
        if isEnabled && level >= minimumLevel {
            dispatchLog(of: level, message: message(), function: function, file: file, line: line)
        }
    }
    
    fileprivate func maybeLog(_ level: LogPriorityLevel, optionalMessage: (() -> String?), function: String, file: String,
                     line: Int) {
        
        if isEnabled && level >= minimumLevel, let message = optionalMessage() {
            dispatchLog(of: level, message: message, function: function, file: file, line: line)
        }
    }
    
    private func dispatchLog(of level: LogPriorityLevel, message: String, function: String, file: String, line: Int) {
        var threadID: UInt64 = 0
        pthread_threadid_np(nil, &threadID)
        
        let event = LogEvent(level: level, message: message, date: Date(), function: function, file: file,
                             line: line, threadID: threadID)
        
        queue.async {
            for destination in self.destinations {
                let formatter = destination.formatter ?? self.defaultFormatter
                
                if let queue = destination.queue {
                    queue.async {
                        let entry = formatter.formatEvent(event)
                        destination.write(entry)
                    }
                } else {
                    let entry = formatter.formatEvent(event)
                    destination.write(entry)
                }
            }
        }
    }
    
    private static func notifyDidRemoveDestination(_ destination: LogDestination) {
        if let queue = destination.queue {
            queue.async(execute: destination.deinitialize)
        } else {
            destination.deinitialize()
        }
    }
}

// MARK: - Logger + Logging Methods

public extension Logger {
    
    func debug(_ message: @autoclosure () -> String, function: String = #function, file: String = #file,
               line: Int = #line) {
        
        log(.debug, message: message, function: function, file: file, line: line)
    }
    
    func debug(function: String = #function, file: String = #file, line: Int = #line, _ closure: () -> String?) {
        maybeLog(.debug, optionalMessage: closure, function: function, file: file, line: line)
    }
    
    func info(_ message: @autoclosure () -> String, function: String = #function, file: String = #file,
               line: Int = #line) {
        
        log(.info, message: message, function: function, file: file, line: line)
    }
    
    func info(function: String = #function, file: String = #file, line: Int = #line, _ closure: () -> String?) {
        maybeLog(.info, optionalMessage: closure, function: function, file: file, line: line)
    }
    
    func warn(_ message: @autoclosure () -> String, function: String = #function, file: String = #file,
               line: Int = #line) {
        
        log(.warn, message: message, function: function, file: file, line: line)
    }
    
    func warn(function: String = #function, file: String = #file, line: Int = #line, _ closure: () -> String?) {
        maybeLog(.warn, optionalMessage: closure, function: function, file: file, line: line)
    }
    
    func error(_ message: @autoclosure () -> String, function: String = #function, file: String = #file,
               line: Int = #line) {
        
        log(.error, message: message, function: function, file: file, line: line)
    }
    
    func error(function: String = #function, file: String = #file, line: Int = #line, _ closure: () -> String?) {
        maybeLog(.error, optionalMessage: closure, function: function, file: file, line: line)
    }
    
    func fatal(_ message: @autoclosure () -> String, function: String = #function, file: String = #file,
               line: Int = #line) -> Never {
        
        log(.fatal, message: message, function: function, file: file, line: line)
        synchronize()
        exit(EXIT_FAILURE)
    }
}
