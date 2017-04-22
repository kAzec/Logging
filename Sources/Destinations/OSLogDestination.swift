//
//  OSLogDestination.swift
//  Logging
//
//  Created by Fengwei Liu on 15/04/2017.
//  Copyright © 2017 kAzec. All rights reserved.
//

import Dispatch
import os.log

@available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *)
public final class OSLogDestination : LogDestination {
    
    public let queue: DispatchQueue?
    public let formatter: LogFormatter?
    
    public let subsystem: String?
    public let category: String?
    
    private let log: OSLog
    
    public init(subsystem: String = App.loggingIdentifier, category: String, formatter: LogFormatter? = .barebone,
                queue: DispatchQueue? = DispatchQueue(label: "com.uncosmos.Logging.oslog", qos: .background)) {
        
        self.subsystem = subsystem
        self.category = category
        self.log = OSLog(subsystem: subsystem, category: category)
        self.formatter = formatter
        self.queue = queue
    }
    
    public init(formatter: LogFormatter? = .barebone,
                queue: DispatchQueue? = DispatchQueue(label: "com.uncosmos.Logging.oslog", qos: .background)) {
        
        self.subsystem = nil
        self.category = nil
        self.log = OSLog.default
        self.formatter = formatter
        self.queue = queue
    }
    
    public func write(_ entry: LogEntry) {
        
        let type: OSLogType
        
        switch entry.level {
        case .debug: type = .debug
        case .info: type = .info
        case .warn: type = .default
        case .error, .fatal: type = .error
        }
        
        os_log("%{public}@", log: log, type: type, entry.content)
    }
}
