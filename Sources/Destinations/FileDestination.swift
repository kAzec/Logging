//
//  FileDestination.swift
//  Logging
//
//  Created by 锋炜 刘 on 16/8/21.
//  Copyright © 2016年 kAzec. All rights reserved.
//

import Foundation

public final class FileDestination: LoggerDestination {
    private let fileStream: UnsafeMutablePointer<FILE>?
    private let queue: DispatchQueue
    
    public let filePath: String
    public var formatter: LogFormatter
    public var theme: FileTheme?
    
    public init?(atPath filePath: String = defaultLogFilePath(),
                 formatter: LogFormatter = defaultFileDestinationFormatter(),
                 theme: FileTheme? = nil,
                 queue: DispatchQueue = DispatchQueue(label: "uncosmos.kAzec.Logging.file-destination", attributes: [])) {
        
        // Make sure that filePath is accessible.
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: filePath) {
            let baseDirectory = (filePath as NSString).deletingLastPathComponent
            var isDirectory: ObjCBool = false
            if !(fileManager.fileExists(atPath: baseDirectory, isDirectory: &isDirectory) && isDirectory.boolValue) {
                guard let _ = try? fileManager.createDirectory(atPath: baseDirectory, withIntermediateDirectories: true, attributes: nil) else {
                    return nil
                }
            }
        }
        
        let file = fopen(filePath, "a")
        guard file != nil else {
            return nil
        }
        
        self.fileStream = file
        self.queue = queue
        
        self.filePath = filePath
        self.formatter = formatter
        self.theme = theme
    }
    
    public func receiveLog(ofLevel level: PriorityLevel, items: [String], separator: String, file: String, line: Int, function: String, date: Date) {
        guard self.fileStream != nil else {
            return
        }
        
        var entry = formatter.formatComponents(level: level, items: items, separator: separator, file: file, line: line, function: function, date: date)
        if let theme = theme {
            entry = theme.colorizeEntry(entry, forLevel: level)
        }
        let log = formatter.formatEntry(entry) + "\n"
        
        let fileStream = self.fileStream
        queue.async {
            fputs(log.UTF8String, fileStream)
        }
    }
    
    public func flush() {
        queue.sync()
        
        if fileStream != nil {
            fflush(fileStream)
        }
    }
    
    deinit {
        queue.sync()
        
        if fileStream != nil {
            fclose(fileStream)
        }
    }
}

private func defaultLogFilePath() -> String {
    let fileName = App.identifier ?? App.name + ".log"
    let filePath = (App.ensuredLogsDirectoryPath as NSString).appendingPathComponent(fileName)
    
    assert(FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil),
           "Failed to create default log file path \(filePath).")
    
    return filePath
}

func defaultFileDestinationFormatter() -> LogFormatter {
    return LogFormatter("[%@] %@ : %@\n", [
        .date(format: "yyyy-MM-dd HH:mm:ss.SSS"),
        .level(.equalWidthByPrependingSpace),
        .message
        ]
    )
}
