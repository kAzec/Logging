//
//  ConsoleDestination.swift
//  Logging
//
//  Created by 锋炜 刘 on 16/8/19.
//  Copyright © 2016年 kAzec. All rights reserved.
//

import Foundation

public final class ConsoleDestination: LoggerDestination {
    private let queue: dispatch_queue_t
    
    public var formatter: LogFormatter
    public var theme: ConsoleTheme?
    
    public init(formatter: LogFormatter = .basic,
                theme: ConsoleTheme? = .solarized(),
                queue: dispatch_queue_t = dispatch_queue_create("uncosmos.kAzec.Logging.console-destination", DISPATCH_QUEUE_SERIAL)) {
        
        self.queue = queue
        
        self.formatter = formatter
        self.theme = theme
    }
    
    public func receiveLog(ofLevel level: PriorityLevel, items: [String], separator: String, file: String, line: Int, function: String, date: NSDate) {
        var entry = formatter.formatComponents(level: level, items: items, separator: separator, file: file, line: line, function: function, date: date)
        if let theme = theme {
            entry = theme.colorizeEntry(entry, forLevel: level)
        }
        let log = formatter.formatEntry(entry)
        
        dispatch_async(queue) {
            print(log)
        }
    }
    
    public func flush() {
        queue.sync()
    }
    
    deinit {
        flush()
    }
}