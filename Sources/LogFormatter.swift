//
//  LogFormatter.swift
//  Logging
//
//  Created by 锋炜 刘 on 16/8/18.
//  Copyright © 2016年 kAzec. All rights reserved.
//

import Foundation

/**
 *  Log Formatter.
 */
public struct LogFormatter: CustomStringConvertible {
    
    private let format: String
    private let components: [LogFormattingComponent]
    
    /// The date formatter used by the receiver to format date. 
    ///
    /// **Note:** Setting its `dateFormat` property won't affect the receiver's output.
    public let dateFormatter = DateFormatter()
    
    /// The receiver textual representation.
    public var description: String {
        return String(format: format, arguments: components.map{ $0.description as CVarArg })
    }
    
    /**
     Initializes a new formatter with the specified format and components.
     
     - parameter format:     The formatter's format.
     - parameter components: The formatter's components.
     
     - returns: A new formatter.
     */
    public init(_ format: String, _ components: [LogFormattingComponent]) {
        self.format = format
        self.components = components
    }

    func formatComponents(level: PriorityLevel, items: [String], separator: String, file: String, line: Int, function: String, date: Date) -> LogEntry {
        return LogEntry(components.map { option in
            switch option {
            case .date(let format):
                return (.date, formatDate(date, format: format))
            case .level(let option):
                return (.level, formatLevel(level, formattingOption: option))
            case .file(let fullPath, let withExtension):
                return (.file, formatFile(file, fullPath: fullPath, withExtension: withExtension))
            case .function:
                return (.function, formatFunction(function))
            case .line:
                return (.line, String(line))
            case .location:
                return (.location, formatLocation(file: file, line: line))
            case .thread:
                return (.thread, formatThread())
            case .message:
                return (.message, formatMessage(items, separator: separator))
            case .custom(identifier: _, content: let content):
                return (.custom, formatCustom(content))
            }
        })
    }
    
    func formatEntry(_ entry: LogEntry) -> String {
        let contents = entry.pairs.map { $0.content as CVarArg }
        return String(format: format, arguments: contents)
    }
}

/**
 Log component formatting option.
 */
public enum LogFormattingComponent: CustomStringConvertible {
    
    case date(format: String)
    case level(LevelFormattingOption)
    case file(fullPath: Bool, withExtension: Bool)
    case line
    case function
    case location
    case thread
    case message
    case custom(identifier: String, content: CustomContentFormattingOption)
    
    /// Description.
    public var description: String {
        switch self {
        case .date(format: let format):
            return "#date(format: \"\(format)\")"
        case .level(let option):
            return "#level(\(option))"
        case .file(fullPath: let fullPath, withExtension: let withExtension):
            return "#file(fullPath: \(fullPath), withExtension: \(withExtension))"
        case .line:
            return "#line"
        case .function:
            return "#function"
        case .location:
            return "#location"
        case .thread:
            return "#thread"
        case .message:
            return "#message"
        case .custom(identifier: let identifier, content: let content):
            return "#custom(identifier: \"\(identifier)\", content: \(content))"
        }
    }
    
    /**
     LogFormatter `.level` component formatting options.
     */
    public enum LevelFormattingOption: CustomStringConvertible {
        case none
        case equalWidthByPrependingSpace
        case equalWidthByAppendingSpace
        case equalWidthByTruncatingTail(width: Int)
        
        /// Description.
        public var description: String {
            switch self {
            case .none:
                return ".none"
            case .equalWidthByPrependingSpace:
                return ".equalWidthByPrependingSpace"
            case .equalWidthByAppendingSpace:
                return ".equalWidthByAppendingSpace"
            case .equalWidthByTruncatingTail(width: let width):
                return ".equalWidthByTruncatingTail(width: \(width))"
            }
        }
    }
    
    public enum CustomContentFormattingOption: CustomStringConvertible {
        case text(String)
        case closure((Void) -> String)
        
        /// Description.
        public var description: String {
            switch self {
            case .text(let text):
                return ".text(\"\(text)\")"
            case .closure:
                return ".closure"
            }
        }
    }
}

// MARK: - LogFormatters + Creations
public extension LogFormatter {
    
    /**
     Conveniently create a new log formatter.
     
     - parameter format:     The format of the new log formatter.
     - parameter components: The formatting components of the new log formatter.
     
     - returns: A new log formatter.
     */
    static func format(_ format: String, components: [LogFormattingComponent]) -> LogFormatter {
        return LogFormatter(format, components)
    }
    
    /// Default minimal formatter.
    static let minimal = LogFormatter("%@ | %@ > %@", [
        .level(.equalWidthByTruncatingTail(width: 1)),
        .location,
        .message
        ]
    )
    
    /// Default concise formatter.
    public static let concise = LogFormatter("[%@] %@ | %@ > %@", [
        .date(format: "HH:mm:ss"),
        .level(.equalWidthByTruncatingTail(width: 4)),
        .location,
        .message
        ]
    )
    
    /// Default basic formatter.
    public static let basic = LogFormatter("[%@] %@ | %@ > %@", [
        .date(format: "yyyy-MM-dd HH:mm:ss.SSS"),
        .level(.equalWidthByPrependingSpace),
        .location,
        .message
        ]
    )
    
    /// Default verbose formatter.
    public static let verbose = LogFormatter("[%@] %@ | %@:%@ - %@\n> %@", [
        .date(format: "yyyy-MM-dd HH:mm:ss.SSS"),
        .level(.equalWidthByPrependingSpace),
        .file(fullPath: false, withExtension: true),
        .line,
        .function,
        .message
        ]
    )
}

// MARK: - Privates
private extension LogFormatter {
    
    func formatDate(_ date: Date, format: String) -> String {
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }

    func formatLevel(_ level: PriorityLevel, formattingOption: LogFormattingComponent.LevelFormattingOption) -> String {
        let symbol = level.symbol
        
        switch formattingOption {
        case .none:
            return symbol
        case .equalWidthByAppendingSpace:
            return symbol.characters.count == 4 ? symbol + " " : symbol
        case .equalWidthByPrependingSpace:
            return symbol.characters.count == 4 ? " " + symbol : symbol
        case .equalWidthByTruncatingTail(width: let width):
            return symbol.characters.count > width ? symbol.substring(to: symbol.characters.index(symbol.startIndex, offsetBy: width)) : symbol
        }
    }
    
    func formatFile(_ file: String, fullPath: Bool, withExtension: Bool) -> String {
        var file = file
        
        if !fullPath      {
            file = (file as NSString).lastPathComponent
        }
        
        if !withExtension {
            file = (file as NSString).deletingPathExtension
        }
        
        return file
    }
    
    func formatFunction(_ function: String) -> String {
        if !function.hasSuffix(")") {
            return function + "(...)"
        } else {
            return function
        }
    }
    
    func formatLocation(file: String, line: Int) -> String {
        return formatFile(file, fullPath: false, withExtension: true) + ":" + String(line)
    }
    
    func formatThread() -> String {
        if let threadName = Thread.current.name , !threadName.isEmpty {
            return threadName
        } else if Thread.isMainThread {
            return "main"
        } else if !DispatchQueue.main.label.isEmpty {
            return DispatchQueue.main.label
        } else {
            return Thread.current.description
        }
    }
    
    func formatMessage(_ items: [String], separator: String) -> String {
        return items.joined(separator: separator)
    }
    
    func formatCustom(_ contentFormattingOption: LogFormattingComponent.CustomContentFormattingOption) -> String {
        switch contentFormattingOption {
        case .text(let text):
            return text
        case .closure(let closure):
            return closure()
        }
    }
}
