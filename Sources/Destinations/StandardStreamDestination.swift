//
//  StandardStreamDestination.swift
//  Logging
//
//  Created by Fengwei Liu on 15/04/2017.
//  Copyright © 2017 kAzec. All rights reserved.
//

import Dispatch
import Darwin.C.stdio

public final class StandardStreamDestination : LogDestination {
    
    /// The minimum priority level that determines whether a log entry should be written to `stderr` or `stdout`.
    ///
    /// The default value is `.warn`
    public let minimumStandardErrorLevel: LogPriorityLevel
    
    public let formatter: LogFormatter?
    public let queue: DispatchQueue?
    
    public init(minimumStandardErrorLevel: LogPriorityLevel = .warn, formatter: LogFormatter? = nil,
                queue: DispatchQueue? = nil) {
        
        self.minimumStandardErrorLevel = minimumStandardErrorLevel
        self.formatter = formatter
        self.queue = queue
    }
    
    public func write(_ entry: LogEntry) {
        let stream = entry.level >= minimumStandardErrorLevel ? stderr : stdout
        fputs(entry.content, stream)
    }
    
    public func synchronize() {
        fflush(stdout)
        fflush(stderr)
    }
}
