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
    
    typealias LogReceiver = (_ items: [String], _ separator: String, _ file: String, _ line: Int, _ function: String) -> Void
    
    func log(_ level: PriorityLevel) -> LogReceiver? {
        guard enabled && level >= self.minimumLevel else {
            return nil
        }
        
        return { items, separator, file, line, function in
            for destination in self.destinations {
                destination.receiveLog(of: level, items: items, separator: separator, file: file, line: line, function: function, date: Date())
            }
        }
    }
}

/**
 *  Logger Destination Protocol.
 */
public protocol LoggerDestination: class {
    
    func receiveLog(of level: PriorityLevel, items: [String], separator: String, file: String, line: Int, function: String, date: Date)
    func flush()
}

/// Logger Any Destination
public final class AnyDestination: LoggerDestination {
    
    public typealias Receiver = (_ level: PriorityLevel, _ items: [String], _ separator: String, _ file: String, _ line: Int, _ function: String, _ date: Date) -> Void
    
    private let receiver: Receiver
    private let flusher: ((Void) -> Void)?
    
    public init(receiver: @escaping Receiver, flusher: ((Void) -> Void)? = nil) {
        self.receiver = receiver
        self.flusher = flusher
    }
    
    public func receiveLog(of level: PriorityLevel, items: [String], separator: String, file: String, line: Int, function: String, date: Date) {
        receiver(level, items, separator, file, line, function, date)
    }
    
    public func flush() {
        flusher?()
    }
}
