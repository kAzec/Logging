//
//  LogDestination.swift
//  Logging
//
//  Created by Fengwei Liu on 14/04/2017.
//  Copyright © 2017 kAzec. All rights reserved.
//

import Dispatch

public protocol LogDestination: class {
    
    /// The formatter used by the logger to format a log event to the log entry that this destination writes down.
    ///
    /// **Note:** If this returns `nil`, the logger will use its internal formatter as a substitute.
    var formatter: LogFormatter? { get }
    
    /// The dispatch queue used by the logger to invoke multiple methods asynchronously on this destination(see below).
    ///
    /// **Note:** If this returns `nil`, the logger will use its internal queue as a substitute.
    var queue: DispatchQueue? { get }
    
    /// Make any necessay preparations for receving log entries.
    ///
    /// **Note:** This method is invoked by the logger after it added this destination and is guaranteed to be invoked
    /// asynchronously on either the logger's internal queue or this destination's internal queue.
    func initialize()
    
    /// Teardown resources that will no longer be used and finalize writing log entries down.
    ///
    /// **Note:** This method is invoked by the logger after it removed this destination and is guaranteed to be invoked
    /// asynchronously on either the logger's internal queue or this destination's internal queue.
    func deinitialize()
    
    /// Write down a log entry.
    ///
    /// **Note:** This method is invoked by the logger when it received a log event and is guaranteed to be invoked
    /// asynchronously on either the logger's internal queue or this destination's internal queue.
    func write(_ entry: LogEntry)
    
    /// Flush any buffer used by this destination to the real storage(eg. log file, database).
    ///
    /// **Note:** This method is invoked by the logger when it is performing synchronization and is guaranteed to be
    /// invoked asynchronously on either the logger's internal queue or this destination's internal queue.
    func synchronize()
}


// MARK: - Default Empty Implementations

public extension LogDestination {
    
    func initialize() {  }
    func deinitialize() {  }
    
    func synchronize() {  }
}
