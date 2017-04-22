//
//  LogEntry.swift
//  Logging
//
//  Created by Fengwei Liu on 14/04/2017.
//  Copyright © 2017 kAzec. All rights reserved.
//

import Foundation

/// Log's priority level enums.
public enum LogPriorityLevel : Int, CustomStringConvertible, Comparable {
    
    case debug = 0, info, warn, error, fatal
    
    public static let numberOfLevels = 5
    
    public var description: String {
        switch self {
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .warn:
            return "WARN"
        case .error:
            return "ERROR"
        case .fatal:
            return "FATAL"
        }
    }
    
    public static func <(x: LogPriorityLevel, y: LogPriorityLevel) -> Bool {
        return x.rawValue < y.rawValue
    }
}
