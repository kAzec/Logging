//
//  PriorityLevel.swift
//  Logging
//
//  Created by 锋炜 刘 on 16/8/18.
//  Copyright © 2016年 kAzec. All rights reserved.
//

import Foundation

/// Log's priority level enums.
public enum PriorityLevel : Int {
    
    case trace, debug, info, warn, error, fatal
    
    static let numberOfLevels: Int = 6
    
    var symbol: String {
        switch self {
        case .trace:
            return "TRACE"
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
}

// MARK: - PriorityLevel + Comparable
extension PriorityLevel : Comparable {  }

public func <(x: PriorityLevel, y: PriorityLevel) -> Bool {
    return x.rawValue < y.rawValue
}
