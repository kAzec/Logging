//
//  ASLDestination.swift
//  Logging
//
//  Created by 锋炜 刘 on 16/8/19.
//  Copyright © 2016年 kAzec. All rights reserved.
//

import Foundation
import CASL

public final class ASLDestination: LoggerDestination {
    
    private let queue: DispatchQueue
    
    public var formatter: LogFormatter
    public let underlayingClient: asl_object_t
    
    public init(identity: String = App.name,
                facility: String = App.identifier ?? "com.uncosmos.Logging",
                options: Options = .none,
                formatter: LogFormatter = defaultASLDestinationFormatter(),
                queue: DispatchQueue = DispatchQueue(label: "com.uncosmos.Logging.asl", qos: .background)) {
        
        self.queue = queue
        self.formatter = formatter
        self.underlayingClient = asl_open(identity.UTF8String, facility.UTF8String, options.rawValue)
        
        if asl_get_type(underlayingClient) == ASL_TYPE_UNDEF {
            assertionFailure("Failed to initialize asl client.")
        } else {
            asl_set_filter(underlayingClient, priorityLevelFilterMaskUpTo(ASL_LEVEL_DEBUG))
        }
    }
    
    public func receiveLog(of level: PriorityLevel, items: [String], separator: String, file: String, line: Int, function: String, date: Date) {
        queue.async {
            let entry = self.formatter.formatComponents(level: level, items: items, separator: separator, file: file, line: line, function: function, date: date)
            let log = self.formatter.formatEntry(entry)
            let message = makeASLMessage(forLevel: level, content: log)
            
            asl_send(self.underlayingClient, message)
            
            asl_release(message)
        }
    }
    
    public func flush() {
        queue.sync()
        flushStdErr()
    }
    
    private func flushStdErr() {
        let optionsString = asl_get(underlayingClient, ASL_KEY_OPTION)
        
        if optionsString != nil {
            let options = Options(rawValue: UInt32(String(describing: optionsString))!)
            if options.contains(.stdErr) {
                fflush(stderr)
            }
        }
    }
    
    deinit {
        flushStdErr()
        asl_close(underlayingClient)
    }
    
    public struct Options: OptionSet {
        public let rawValue: UInt32
        
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        /// An `ASLDestination.Options` value wherein none of the bit flags are set.
        public static let none      = Options(rawValue: 0)
        
        /// An `ASLDestination.Options` value with the `ASL_OPT_STDERR` flag set.
        public static let stdErr    = Options(rawValue: 0x00000001)
        
        /// An `ASLDestination.Options` value with the `ASL_OPT_NO_DELAY` flag set.
        public static let noDelay   = Options(rawValue: 0x00000002)
        
        /// An `ASLDestination.Options` value with the `ASL_OPT_NO_REMOTE` flag set.
        public static let noRemote  = Options(rawValue: 0x00000004)
    }

}

private func priorityLevelFilterMaskUpTo(_ level: Int32) -> Int32 {
    return (1 << (level + 1)) - 1
}

private func aslPrioprityLevelString(fromLevel level: PriorityLevel) -> String {
    switch level {
    case .trace, .debug:
        return ASL_STRING_DEBUG
    case .info:
        return ASL_STRING_NOTICE
    case .warn:
        return ASL_STRING_WARNING
    case .error:
        return ASL_STRING_ERR
    case .fatal:
        return ASL_STRING_CRIT
    }
}

private func makeASLMessage(forLevel level: PriorityLevel, content: String) -> asl_object_t {
    let message = asl_new(UInt32(ASL_TYPE_MSG))
    asl_set(message, ASL_KEY_LEVEL, aslPrioprityLevelString(fromLevel: level))
    asl_set(message, ASL_KEY_MSG, content.UTF8String)
    // ASL_KEY_READ_UID attribute determines the processes that can
    // read this log entry. -1 means anyone can read.
    asl_set(message, ASL_KEY_READ_UID, "-1")
    return message!
}

private func defaultASLDestinationFormatter() -> LogFormatter {
    return LogFormatter("%@ : %@", [
        .level(.none),
        .message
        ]
    )
}
