//
//  LogEntry.swift
//  Logging
//
//  Created by Fengwei Liu on 14/04/2017.
//  Copyright © 2017 kAzec. All rights reserved.
//

import Dispatch
import CASL

@available(iOS, deprecated: 10.0, message: "Use OSLogDestination instead.")
@available(macOS, deprecated: 10.12, message: "Use OSLogDestination instead.")
@available(tvOS, deprecated: 10.0, message: "Use OSLogDestination instead.")
@available(watchOS, deprecated: 3.0, message: "Use OSLogDestination instead.")
public final class ASLDestination: LogDestination {
    
    public let queue: DispatchQueue?
    public let formatter: LogFormatter?
    
    /// The identity of the asl client.
    public let identity: String
    
    /// The facility of the asl client.
    public let facility: String
    
    private var client: asl_object_t?
    
    private var isConnected: Bool {
        return client != nil && asl_get_type(client) != ASL_TYPE_UNDEF
    }
    
    public init(identity: String = ProcessInfo.processInfo.processName,
                facility: String = Bundle.main.bundleIdentifier ?? "com.uncosmos.Logging",
                formatter: LogFormatter? = .barebone,
                queue: DispatchQueue? = DispatchQueue(label: "com.uncosmos.Logging.asl", qos: .background)) {
        
        self.queue = queue
        self.formatter = formatter
        self.identity = identity
        self.facility = facility
        self.client = nil
    }
    
    public func initialize() {
        self.client = facility.withCString { facility in
            return identity.withCString { identity in
                asl_open(identity, facility, 0)
            }
        }
        
        if isConnected {
            asl_set_filter(client, levelFilterMask(upTo: ASL_LEVEL_DEBUG))
        } else {
            assertionFailure("Failed to initialize asl client.")
        }
    }
    
    public func deinitialize() {
        asl_close(client)
        self.client = nil
    }
    
    public func write(_ entry: LogEntry) {
        if isConnected {
            let aslMessage = asl_new(UInt32(ASL_TYPE_MSG))
            let (time, timeFraction) = modf(entry.date.timeIntervalSince1970)
            
            if asl_set(aslMessage, ASL_KEY_LEVEL, aslLevelStrings[entry.level.rawValue]) == 0
                && entry.content.withCString({ asl_set(aslMessage, ASL_KEY_MSG, $0) }) == 0
                && asl_set(aslMessage, ASL_KEY_READ_UID, String(geteuid())) == 0
                && asl_set(aslMessage, ASL_KEY_TIME, String(Int(time))) == 0
                && asl_set(aslMessage, ASL_KEY_TIME_NSEC, String(Int(timeFraction * 10e9))) == 0 {
                
                asl_send(client, aslMessage)
            }
            
            asl_release(aslMessage)
        }
    }
}

private func levelFilterMask(upTo level: Int32) -> Int32 {
    return (1 << (level + 1)) - 1
}

private let aslLevelStrings = [
    ASL_STRING_DEBUG,
    ASL_STRING_NOTICE,
    ASL_STRING_WARNING,
    ASL_STRING_ERR,
    ASL_STRING_CRIT
]
