//
//  Logger.swift
//  Logging
//
//  Created by 锋炜 刘 on 16/8/18.
//  Copyright © 2016年 kAzec. All rights reserved.
//

import Foundation

public final class Logger: Logging {
    /// Return `self`.
    public var logger: Logger {
        return self
    }
    
    /// The logger's enabled state.
    public var enabled = true
    
    /// The logger's minimum level of severity.
    public var minimumLevel: PriorityLevel
    
    /// The logger's destinations.
    public var destinations: [LoggerDestination]
    
    /**
     Creates and returns a new logger.
     
     - parameter minimumLevel: The minimum level of severity.
     - parameter formatter:    The new logger's formatter.
     - parameter destinations: The new logger's destinations.
     
     - returns: The new logger.
     */
    public init(_ minimumLevel: PriorityLevel = .trace, destinations: [LoggerDestination] = []) {
        self.minimumLevel = minimumLevel
        self.destinations = destinations
    }
    
    /**
     Flush all asynchronous destinations.
     */
    public func flush() {
        for destination in destinations {
            destination.flush()
        }
    }
    
    typealias LogReceiver = (items: [String], separator: String, file: String, line: Int, function: String) -> Void
    
    func log(level: PriorityLevel) -> LogReceiver? {
        guard enabled && level >= self.minimumLevel else {
            return nil
        }
        
        return { items, separator, file, line, function in
            for destination in self.destinations {
                destination.receiveLog(ofLevel: level, items: items, separator: separator, file: file, line: line, function: function, date: NSDate())
            }
        }
    }
}

/**
 *  Logger Destination Protocol.
 */
public protocol LoggerDestination: class {
    func receiveLog(ofLevel level: PriorityLevel, items: [String], separator: String, file: String, line: Int, function: String, date: NSDate)
    func flush()
}

/// Logger Any Destination
public final class AnyDestination: LoggerDestination {
    public typealias Receiver = (level: PriorityLevel, items: [String], separator: String, file: String, line: Int, function: String, date: NSDate) -> Void
    
    private let receiver: Receiver
    private let flusher: (Void -> Void)?
    
    public init(receiver: Receiver, flusher: (Void -> Void)? = nil) {
        self.receiver = receiver
        self.flusher = flusher
    }
    
    public func receiveLog(ofLevel level: PriorityLevel, items: [String], separator: String, file: String, line: Int, function: String, date: NSDate) {
        receiver(level: level, items: items, separator: separator, file: file, line: line, function: function, date: date)
    }
    
    public func flush() {
        flusher?()
    }
}