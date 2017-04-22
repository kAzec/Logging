//
//  LogEntry.swift
//  Logging
//
//  Created by Fengwei Liu on 14/04/2017.
//  Copyright © 2017 kAzec. All rights reserved.
//

import Foundation

public struct LogEntry {
    
    public let level: LogPriorityLevel
    public let content: String
    public let date: Date
    public let threadID: UInt64
}
