//
//  LogEntry.swift
//  Logging
//
//  Created by Fengwei Liu on 14/04/2017.
//  Copyright © 2017 kAzec. All rights reserved.
//

import Foundation

public final class FileDestination: LogDestination {
    
    /// The url of the logging file.
    public let fileURL: URL
    
    public let formatter: LogFormatter?
    public let queue: DispatchQueue?
    
    private var fileHandle: FileHandle?
    
    public init(fileURL: URL = FileDestination.makeDefaultFileURL(),
                 formatter: LogFormatter? = nil,
                 queue: DispatchQueue? = DispatchQueue(label: "com.uncosmos.Logging.file", qos: .background)) {
        
        self.fileURL = fileURL
        self.formatter = formatter
        self.queue = queue
    }
    
    public func initialize() {
        let fileDescriptor = open(fileURL.path, O_RDONLY | O_CREAT)
        guard fileDescriptor >= 0 else {
            print("<com.uncosmos.Logging> File destination unable to open file at \(fileURL.path) when initializing.")
            return
        }
        
        fileHandle = FileHandle(fileDescriptor: fileDescriptor)
    }
    
    public func deinitialize() {
        if let fileHandle = fileHandle  {
            fileHandle.synchronizeFile()
            fileHandle.closeFile()
        }
    }
    
    public func write(_ entry: LogEntry) {
        guard let fileHandle = fileHandle, let data = entry.content.data(using: .utf8) else {
            return
        }
        
        fileHandle.write(data)
    }
    
    public func synchronize() {
        fileHandle?.synchronizeFile()
    }
    
    private static func makeDefaultFileURL() -> URL {
        return App.makeLogsDirectory().appendingPathComponent(App.loggingIdentifier + ".log", isDirectory: false)
    }
}
