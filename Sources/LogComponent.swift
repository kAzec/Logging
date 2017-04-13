//
//  LogComponent.swift
//  Logging
//
//  Created by 锋炜 刘 on 16/8/20.
//  Copyright © 2016年 kAzec. All rights reserved.
//

import Foundation

/**
 Log components option-set.
 */
public struct LogComponents: OptionSet {
    
    public let rawValue : Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let date     = LogComponents(rawValue: 1 << 0)
    public static let level    = LogComponents(rawValue: 1 << 1)
    public static let file     = LogComponents(rawValue: 1 << 2)
    public static let line     = LogComponents(rawValue: 1 << 3)
    public static let function = LogComponents(rawValue: 1 << 4)
    public static let location = LogComponents(rawValue: 1 << 5)
    public static let thread   = LogComponents(rawValue: 1 << 6)
    public static let message  = LogComponents(rawValue: 1 << 7)
    public static let custom   = LogComponents(rawValue: 1 << 8)
    
    public static let all: LogComponents = [date, level, file, line, function, location, thread, message, custom]
    
    static var allIndividuals: [LogComponents] {
        return [date, level, file, line, function, location, thread, message, custom]
    }
    
    var isIndividual: Bool {
        return LogComponents.allIndividuals.contains(self)
    }
}

struct LogEntry {
    let pairs: [(component: LogComponents, content: String)]
    
    init(_ pairs: [(component: LogComponents, content: String)]) {
        assert(!pairs.contains{ !$0.component.isIndividual }, "Pair's log component in a log entry must not be union of components.")
        self.pairs = pairs
    }
}
