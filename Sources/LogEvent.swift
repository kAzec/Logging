//
//  LogEvent.swift
//  Logging
//
//  Created by Fengwei Liu on 14/04/2017.
//  Copyright © 2017 kAzec. All rights reserved.
//

import Foundation

public struct LogEvent {
    
    public let level: LogPriorityLevel
    public let message: String
    public let date: Date
    public let function: String
    public let file: String
    public let line: Int
    public let threadID: UInt64
}
