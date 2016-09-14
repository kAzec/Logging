//
//  Logging.swift
//  Logging
//
//  Created by 锋炜 刘 on 16/8/18.
//  Copyright © 2016年 kAzec. All rights reserved.
//

import Foundation

/**
 *  Logging Protocol.
 */
public protocol Logging {
    var logger: Logger { get }
}

// MARK: - Logging Methods
public extension Logging {
    /**
     Log message with trace severity level.
     
     - parameter message:    The message to log.
     - parameter file:       The file in which the log happens.
     - parameter line:       The line at which the log happens.
     - parameter function:   The function in which the log happens.
     */
    public func trace(_ message: @autoclosure (Void) -> Any, file: String = #file, line: Int = #line, function: String = #function) {
        logger.log(.trace)?([String(describing: message())], "", file, line, function)
    }
    
    /**
     Log items with trace severity level.
     
     - parameter items:      The items to log.
     - parameter separator:  The separator between the items.
     - parameter file:       The file in which the log happens.
     - parameter line:       The line at which the log happens.
     - parameter function:   The function in which the log happens.
     */
    public func trace<S: Sequence>(_ items: @autoclosure (Void) -> S, separator: String = " ", file: String = #file, line: Int = #line, function: String = #function) {
        logger.log(.trace)?(items().map{ String(describing: $0) }, separator, file, line, function)
    }
    
    /**
     Log closure result with a trace severity level.
     
     The closure will be evaluated only if the logger is enabled.
     
     If the result of closure is nil, the log won't be made.
     
     - parameter file:       The file in which the log happens.
     - parameter line:       The line at which the log happens.
     - parameter function:   The function in which the log happens.
     - parameter closure:    The closure to evaluate the log message.
     */
    public func trace(file: String = #file, line: Int = #line, function: String = #function, closure: (Void) -> String?) {
        if let entry = logger.log(.trace), let message = closure() {
            entry([message], "", file, line, function)
        }
    }
    
    /**
     Log application's execution trace information.
     
     - parameter file:       The file in which the log happens.
     - parameter line:       The line at which the log happens.
     - parameter function:   The function in which the log happens.
     */
    public func trace(file: String = #file, line: Int = #line, function: String = #function) {
        var threadID: UInt64 = 0
        pthread_threadid_np(nil, &threadID)
        
        logger.log(.trace)?(["Function: \(function). Location: \(file):\(line). Thread ID: \(threadID)"], "", file, line, function)
    }
    
    /**
     Log message with a debug severity level.
     
     - parameter message:    The message to log.
     - parameter file:       The file in which the log happens.
     - parameter line:       The line at which the log happens.
     - parameter function:   The function in which the log happens.
     */
    public func debug(_ message: @autoclosure (Void) -> Any, file: String = #file, line: Int = #line, function: String = #function) {
        logger.log(.debug)?([String(describing: message())], "", file, line, function)
    }
    
    /**
     Log items with a debug severity level.
     
     - parameter items:      The items to log.
     - parameter separator:  The separator between the items.
     - parameter file:       The file in which the log happens.
     - parameter line:       The line at which the log happens.
     - parameter function:   The function in which the log happens.
     */
    public func debug<S: Sequence>(_ items: @autoclosure (Void) -> S, separator: String = " ", file: String = #file, line: Int = #line, function: String = #function) {
        logger.log(.debug)?(items().map{ String(describing: $0) }, separator, file, line, function)
    }
    
    /**
     Log closure result with a debug severity level.
     
     The closure will be evaluated only if the logger is enabled and it's `minimumLevel` is lower
     or equal to `.debug`
     
     If the result of closure is nil, the log won't be made.
     
     - parameter terminator: The terminator of the log message.
     - parameter file:       The file in which the log happens.
     - parameter line:       The line at which the log happens.
     - parameter function:   The function in which the log happens.
     - parameter closure:    The closure to evaluate the log message.
     */
    public func debug(_ file: String = #file, line: Int = #line, function: String = #function, closure: (Void) -> String?) {
        if let entry = logger.log(.debug), let message = closure() {
            entry([message], "", file, line, function)
        }
    }
    
    /**
     Log message with a info severity level.
     
     - parameter message:    The message to log.
     - parameter file:       The file in which the log happens.
     - parameter line:       The line at which the log happens.
     - parameter function:   The function in which the log happens.
     */
    public func info(_ message: @autoclosure (Void) -> Any, file: String = #file, line: Int = #line, function: String = #function) {
        logger.log(.info)?([String(describing: message())], "", file, line, function)
    }
    
    /**
     Log items with a info severity level.
     
     - parameter items:      The items to log.
     - parameter separator:  The separator between the items.
     - parameter file:       The file in which the log happens.
     - parameter line:       The line at which the log happens.
     - parameter function:   The function in which the log happens.
     */
    public func info<S: Sequence>(_ items: @autoclosure (Void) -> S, separator: String = " ", file: String = #file, line: Int = #line, function: String = #function) {
        logger.log(.info)?(items().map{ String(describing: $0) }, separator, file, line, function)
    }
    
    /**
     Log closure result with a info severity level.
     
     The closure will be evaluated only if the logger is enabled and it's `minimumLevel` is lower
     or equal to `.info`
     
     If the result of closure is nil, the log won't be made.
     
     - parameter file:       The file in which the log happens.
     - parameter line:       The line at which the log happens.
     - parameter function:   The function in which the log happens.
     - parameter closure:    The closure to evaluate the log message.
     */
    public func info(_ file: String = #file, line: Int = #line, function: String = #function, closure: (Void) -> String?) {
        if let entry = logger.log(.info), let message = closure() {
            entry([message], "", file, line, function)
        }
    }
    
    /**
     Log message with a warn severity level.
     
     - parameter message:    The message to log.
     - parameter file:       The file in which the log happens.
     - parameter line:       The line at which the log happens.
     - parameter function:   The function in which the log happens.
     */
    public func warn(_ message: @autoclosure (Void) -> Any, file: String = #file, line: Int = #line, function: String = #function) {
        logger.log(.warn)?([String(describing: message())], "", file, line, function)
    }
    
    /**
     Log items with a warn severity level.
     
     - parameter items:      The items to log.
     - parameter separator:  The separator between the items.
     - parameter file:       The file in which the log happens.
     - parameter line:       The line at which the log happens.
     - parameter function:   The function in which the log happens.
     */
    public func warn<S: Sequence>(_ items: @autoclosure (Void) -> S, separator: String = " ", file: String = #file, line: Int = #line, function: String = #function) {
        logger.log(.warn)?(items().map{ String(describing: $0) }, separator, file, line, function)
    }
    
    /**
     Log closure result with a warn severity level.
     
     The closure will be evaluated only if the logger is enabled and it's `minimumLevel` is lower
     or equal to `.warn`
     
     If the result of closure is nil, the log won't be made.
     
     - parameter file:       The file in which the log happens.
     - parameter line:       The line at which the log happens.
     - parameter function:   The function in which the log happens.
     - parameter closure:    The closure to evaluate the log message.
     */
    public func warn(_ file: String = #file, line: Int = #line, function: String = #function, closure: (Void) -> String?) {
        if let entry = logger.log(.warn), let message = closure() {
            entry([message], "", file, line, function)
        }
    }
    
    /**
     Log message with a error severity level.
     
     - parameter message:    The message to log.
     - parameter file:       The file in which the log happens.
     - parameter line:       The line at which the log happens.
     - parameter function:   The function in which the log happens.
     */
    public func error(_ message: @autoclosure (Void) -> Any, file: String = #file, line: Int = #line, function: String = #function) {
        logger.log(.error)?([String(describing: message())], "", file, line, function)
    }
    
    /**
     Log items with a error severity level.
     
     - parameter items:      The items to log.
     - parameter separator:  The separator between the items.
     - parameter file:       The file in which the log happens.
     - parameter line:       The line at which the log happens.
     - parameter function:   The function in which the log happens.
     */
    public func error<S: Sequence>(_ items: @autoclosure (Void) -> S, separator: String = " ", file: String = #file, line: Int = #line, function: String = #function) {
        logger.log(.error)?(items().map{ String(describing: $0) }, separator, file, line, function)
    }
    
    /**
     Log closure result with a error severity level.
     
     The closure will be evaluated only if the logger is enabled and it's `minimumLevel` is lower
     or equal to `.error`
     
     If the result of closure is nil, the log won't be made.
     
     - parameter file:       The file in which the log happens.
     - parameter line:       The line at which the log happens.
     - parameter function:   The function in which the log happens.
     - parameter closure:    The closure to evaluate the log message.
     */
    public func error(_ file: String = #file, line: Int = #line, function: String = #function, closure: (Void) -> String?) {
        if let entry = logger.log(.error), let message = closure() {
            entry([message], "", file, line, function)
        }
    }
    
    /**
     Log message with a fatal severity level then terminate with `EXIT_FAILURE`.
     
     - parameter message:    The message to log.
     - parameter file:       The file in which the log happens.
     - parameter line:       The line at which the log happens.
     - parameter function:   The function in which the log happens.
     */
    
    public func fatal(_ message: @autoclosure (Void) -> Any, file: String = #file, line: Int = #line, function: String = #function) -> Never  {
        logger.log(.fatal)?([String(describing: message())], "", file, line, function)
        logger.flush()
        exit(EXIT_FAILURE)
    }
    
    /**
     Log items with a fatal severity level then terminate with `EXIT_FAILURE`.
     
     - parameter items:      The items to log.
     - parameter separator:  The separator between the items.
     - parameter file:       The file in which the log happens.
     - parameter line:       The line at which the log happens.
     - parameter function:   The function in which the log happens.
     */
    
    public func fatal<S: Sequence>(_ items: @autoclosure (Void) -> S, separator: String = " ", file: String = #file, line: Int = #line, function: String = #function) -> Never  {
        logger.log(.fatal)?(items().map{ String(describing: $0) }, separator, file, line, function)
        logger.flush()
        exit(EXIT_FAILURE)
    }
    
    /**
     Log closure result with a fatal severity level then then terminate with `EXIT_FAILURE`.
     Unlike other variants, the closure is guaranteed to be evaluated even if the logger is not enabled.
     
     - parameter file:       The file in which the log happens.
     - parameter line:       The line at which the log happens.
     - parameter function:   The function in which the log happens.
     - parameter closure:    The closure to evaluate the log message.
     */
    
    public func fatal(file: String = #file, line: Int = #line, function: String = #function, closure: (Void) -> String) -> Never  {
        let item = closure()
        logger.log(.fatal)?([item], "", file, line, function)
        logger.flush()
        exit(EXIT_FAILURE)
    }
}

/**
 *  Static Logging Protocol.
 */
public protocol StaticLogging {
    static var logger: Logger { get }
}

// MARK: - StaticLogging Methods
public extension StaticLogging {
    /**
     Log message with specified severity level.
     
     **Note** The method won't return if `level` is `.fatal`.
     
     - parameter level:      The severity of the log.
     - parameter message:    The message to log.
     - parameter file:       The file in which the log happens.
     - parameter line:       The line at which the log happens.
     - parameter function:   The function in which the log happens.
     */
    public static func log(_ level: PriorityLevel = .debug, _ message: @autoclosure (Void) -> Any, file: String = #file, line: Int = #line, function: String = #function) {
        if case .fatal = level {
            logger.log(.fatal)?([String(describing: message())], "", file, line, function)
            logger.flush()
            exit(EXIT_FAILURE)
        } else {
            logger.log(level)?([String(describing: message())], "", file, line, function)
        }
    }
    
    /**
     Log items with specified severity level.
     
     **Note** The method won't return if `level` is `.fatal`.
     
     - parameter level:      The severity of the log.
     - parameter items:      The items to log.
     - parameter separator:  The separator between the items.
     - parameter file:       The file in which the log happens.
     - parameter line:       The line at which the log happens.
     - parameter function:   The function in which the log happens.
     */
    public static func log<S: Sequence>(_ level: PriorityLevel = .debug, _ items: @autoclosure (Void) -> S, separator: String = " ", file: String = #file, line: Int = #line, function: String = #function) {
        if case .fatal = level {
            logger.log(.fatal)?(items().map{ String(describing: $0) }, separator, file, line, function)
            logger.flush()
            exit(EXIT_FAILURE)
        } else {
            logger.log(.trace)?(items().map{ String(describing: $0) }, separator, file, line, function)
        }
    }
    
    /**
     Log closure result with specified severity level. If the result of closure is nil, the log won't be made.
     
     **Note** The method won't return if `level` is `.fatal`.
     
     - parameter level:      The severity of the log.
     - parameter file:       The file in which the log happens.
     - parameter line:       The line at which the log happens.
     - parameter function:   The function in which the log happens.
     - parameter closure:    The closure to evaluate the log message.
     */
    public static func log(_ level: PriorityLevel = .debug, file: String = #file, line: Int = #line, function: String = #function, closure: (Void) -> String?) {
        if case .fatal = level {
            if let message = closure() {
                logger.log(.fatal)?([message], "", file, line, function)
                logger.flush()
            }
            exit(EXIT_FAILURE)
        } else {
            if let entry = logger.log(level), let message = closure() {
                entry([message], "", file, line, function)
            }
        }
    }
}
