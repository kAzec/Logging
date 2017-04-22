//
//  LogEntry.swift
//  Logging
//
//  Created by Fengwei Liu on 14/04/2017.
//  Copyright © 2017 kAzec. All rights reserved.
//

import Foundation

open class LogFormatter: CustomStringConvertible {
    
    public enum Field: CustomStringConvertible {
        
        public enum LevelStyle {
            case decimal, text, truncatedText(width: Int), custom([String])
        }
        
        public enum DateStyle {
            case unixTime, format(String)
        }
        
        public enum ThreadIDStyle {
            case decimal, hexadecimal
        }
        
        case level(style: LevelStyle)
        case message
        case function
        case file(fullPath: Bool, withExtension: Bool)
        case line
        case location(fullPath: Bool)
        case date(style: DateStyle)
        case threadID(style: ThreadIDStyle)
        case closure(() -> String)
        
        public var description: String {
            switch self {
            case .level(let style):
                return "#level(\(style))"
            case .message:
                return "#message"
            case .function:
                return "#function"
            case .file(fullPath: let fullPath, withExtension: let withExtension):
                return "#file(fullPath: \(fullPath), withExtension: \(withExtension))"
            case .line:
                return "#line"
            case .location(let fullPath):
                return "#location(fullPath: \(fullPath))"
            case .date(let style):
                return "#date(\(style))"
            case .threadID:
                return "#threadID"
            case .closure:
                return "#closure"
            }
        }
    }
    
    public let format: String
    public let fields: [Field]
    public lazy var dateFormatter = DateFormatter()
    
    /// The textual representation of the log formatter.
    public var description: String {
        return String(format: format, arguments: fields.map{ $0.description as CVarArg })
    }
    
    /// Create a new log formatter with the specified format and fields.
    ///
    /// - parameter format: The formatter's format. The newline character will be automatically appended if it does not
    ///                     end with one.
    /// - parameter fields: The formatter's fields.
    ///
    /// - returns: A new log formatter.
    public init(format: String, fields: [Field]) {
        self.format = format.characters.last! == "\n" ? format : format + "\n"
        self.fields = fields
    }
    
    final func formatEvent(_ event: LogEvent) -> LogEntry {
        let formattedComponents: [CVarArg] = fields.map{ field in
            switch field {
            case .level(let style):
                return formatLevel(event.level, style: style)
            case .message:
                return formatMessage(event.message)
            case .function:
                return formatFunction(event.function)
            case .file(let fullPath, let withExtension):
                return formatFile(event.file, fullPath: fullPath, withExtension: withExtension)
            case .line:
                return formatLine(event.line)
            case .location(let fullPath):
                return formatLocation(file: event.file, line: event.line, fullPath: fullPath)
            case .date(let style):
                return formatDate(event.date, style: style)
            case .threadID(let style):
                return formatThreadID(event.threadID, style: style)
            case .closure(let closure):
                return formatClosure(closure)
            }
        }
        
        let messageContent = String(format: format, arguments: formattedComponents)
        return LogEntry(level: event.level, content: messageContent, date: event.date,
                          threadID: event.threadID)
    }
    
    open func formatLevel(_ level: LogPriorityLevel, style: Field.LevelStyle) -> String {
        switch style {
        case .decimal:
            return String(stringInterpolationSegment: level.rawValue)
        case .text:
            let symbol = level.description
            return symbol.characters.count == 4 ? symbol + " " : symbol
        case .truncatedText(let width):
            let symbol = level.description
            if symbol.characters.count > width {
                let truncatedCharacters = symbol.characters.prefix(width)
                return String(truncatedCharacters)
            } else {
                return symbol
            }
        case .custom(let symbols):
            return symbols[level.rawValue]
        }
    }
    
    open func formatMessage(_ message: String) -> String {
        return message
    }
    
    open func formatFunction(_ function: String) -> String {
        if !function.hasSuffix(")") {
            return function + "(...)"
        } else {
            return function
        }
    }
    
    open func formatFile(_ file: String, fullPath: Bool, withExtension: Bool) -> String {
        var file = file
        if !fullPath {
            file = (file as NSString).lastPathComponent
        }
        if !withExtension {
            file = (file as NSString).deletingPathExtension
        }
        return file
    }
    
    open func formatLine(_ line: Int) -> String {
        return String(line)
    }
    
    open func formatLocation(file: String, line: Int, fullPath: Bool) -> String {
        return formatFile(file, fullPath: fullPath, withExtension: true) + ":" + String(line)
    }
    
    open func formatDate(_ date: Date, style: Field.DateStyle) -> String {
        switch style {
        case .unixTime:
            return String(date.timeIntervalSince1970)
        case .format(let dateFormat):
            dateFormatter.dateFormat = dateFormat
            return dateFormatter.string(from: date)
        }
    }
    
    open func formatThreadID(_ threadID: UInt64, style: Field.ThreadIDStyle) -> String {
        switch style {
        case  .decimal:
            return String(threadID)
        case .hexadecimal:
            return String(format: "%08X", threadID)
        }
    }
    
    open func formatClosure(_ closure: () -> String) -> String {
        return closure()
    }
}

// MARK: - LogFormatter Presets

public extension LogFormatter {
    
    internal static let barebone: LogFormatter = .init(format: "%@ %@",
                                                       fields: [.level(style: .custom(levelEmojis)), .message])
 
    static let levelEmojis = ["⚪️", "💬", "⚠️", "‼️", "❌"]
    
    static let minimal: LogFormatter = .init(format: "%@ | %@ > %@",
                                             fields: [.date(style: .format("HH:mm:ss")),
                                                      .level(style: .custom(levelEmojis)), .message])
    
    static let concise: LogFormatter = .init(format: "[%@] %@ | %@ > %@",
                                             fields: [.date(style: .format("HH:mm:ss")),
                                                      .level(style: .custom(levelEmojis)), .location(fullPath: false),
                                                      .message])
    
    static let `default`: LogFormatter = .init(format: "[%@] %@ | %@ > %@",
                                               fields: [.date(style: .format("yyyy-MM-dd HH:mm:ss.SSS")),
                                                        .level(style: .custom(levelEmojis)), .location(fullPath: false),
                                                        .message])
    
    static let verbose: LogFormatter = .init(format: "[%@] %@ | %@ - %@\n> %@",
                                             fields: [.date(style: .format("yyyy-MM-dd HH:mm:ss.SSS")),
                                                      .level(style: .custom(levelEmojis)), .location(fullPath: false),
                                                      .function, .message])
}
