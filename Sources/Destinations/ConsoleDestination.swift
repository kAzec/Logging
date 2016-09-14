//
//  ConsoleDestination.swift
//  Logging
//
//  Created by 锋炜 刘 on 16/8/19.
//  Copyright © 2016年 kAzec. All rights reserved.
//

import Foundation

public final class ConsoleDestination: LoggerDestination {
    private let queue: DispatchQueue
    
    public var formatter: LogFormatter
    public var theme: ConsoleTheme?
    
    public init(formatter: LogFormatter = .basic,
                theme: ConsoleTheme? = .solarized(),
                queue: DispatchQueue = DispatchQueue(label: "uncosmos.kAzec.Logging.console-destination", attributes: [])) {
        
        self.queue = queue
        
        self.formatter = formatter
        self.theme = theme
    }
    
    public func receiveLog(ofLevel level: PriorityLevel, items: [String], separator: String, file: String, line: Int, function: String, date: Date) {
        var entry = formatter.formatComponents(level: level, items: items, separator: separator, file: file, line: line, function: function, date: date)
        if let theme = theme {
            entry = theme.colorizeEntry(entry, forLevel: level)
        }
        let log = formatter.formatEntry(entry)
        
        queue.async {
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
