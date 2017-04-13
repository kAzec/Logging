//
//  ManagedFileDestination.swift
//  Logging
//
//  Created by 锋炜 刘 on 16/8/21.
//  Copyright © 2016年 kAzec. All rights reserved.
//

import Foundation

public final class ManagedFileDestination: LoggerDestination {
    
    private var currentFile: (stream: UnsafeMutablePointer<FILE>, info: FileInfo)?
    private var managedFilesUsedDiskSpace: UInt = 0
    private let queue: DispatchQueue
    
    /// The formatter used by the receiver to format the log message.
    public var formatter: LogFormatter
    
    /// The theme used by the receiver to colorize the log message.
    public var theme: FileTheme?
    
    /// The delegate of the receiver.
    public weak var delegate: ManagedFileDestinationDelegate?
    
    /// Time interval determines how long a log file should be used. After that a new log file will
    /// be created.
    ///
    /// Its default value is `24 * 60 * 60`, aka one day.
    ///
    /// Setting a value less or equal than zero will disable rotating.
    public var rotatingInterval: TimeInterval {
        // These property observers(see below) seem likely that it will cause a little overhead,
        // however it's actually fine since it's rarely change.
        didSet { rotateIfNeeded() }
    }
    
    /// Maximum file size(in bytes) of current log file can use. The limit will be checked every
    /// time a new log message arrives(before it is evaluated and recorded), and if it's
    /// exceeded, the receiver will rotate the current log file and create and use a new one.
    ///
    /// Its default value is 0, which disables this limit.
    public var maximumLogFileSize: UInt {
        didSet { rotateIfNeeded() }
    }
    
    /// Time interval before a log file expires and gets deleted.
    ///
    /// Its default value is `7 * 24 * 60 * 60`, aka 7 days.
    ///
    /// Setting a value less or equal than zero will disable this limit.
    /// 
    /// Setting a value less or equal than `rotatingInterval` will cause the rotated log file to be
    /// deleted immediately.
    public var expirationInterval: TimeInterval {
        didSet { prune() }
    }
    
    /// Maximum number of all managed log files to keep. The limit will be checked every time a log
    /// file gets rotated, and if it's exceeded, starting from the oldest log file, the log files
    /// will be deleted to satisfy the limit.
    ///
    /// Its default value is 0, which disables this limit.
    public var maximumNumberOfLogFiles: Int {
        didSet { prune() }
    }
    
    /// Maximum disk space(in bytes) of all managed log files can use. The limit will be checked
    /// every time a log file gets rotated, and if it's exceeded, starting from the oldest log file,
    /// the log files will be deleted to satisfy the limit.
    ///
    /// Its default value is 0, which disables this limit.
    public var maximumLogFilesDiskSpace: UInt {
        didSet { prune() }
    }
    
    /// The path to the directory where all the log files will be stored.
    public let directoryPath: String
    
    /// The path to the current log file to write logs, if opened.
    public var currentLogFilePath: String? {
        if let currentFileName = currentFile?.info.fileName {
            return makeFilePath(named: currentFileName)
        } else {
            return nil
        }
    }
    
    /// The file informations of all log files managed by the receiver, sorted by creation date
    /// descendingly.
    ///
    /// The first item in the array will be the most recently created log file.
    public private(set) var managedFileInfos: [FileInfo] = []
    
    /// The paths to all log files managed by the receiver, sorted by creation date descendingly.
    ///
    /// The first item in the array will be the most recently created log file.
    public var managedFilePaths: [String] {
        return managedFileInfos.map{ makeFilePath(named: $0.fileName) }
    }

    /// The date formatter used by the receiver to generate names of the log files and determine
    /// creation date of log files.
    ///
    /// By default its `dateFormat` is `yyyy-MM-dd.HH-mm-ss-SSSS`. And the name of the log file will
    /// be, for example:
    /// `com.example.identifier.2016-08-22.23-32-23-4530.log`
    ///
    /// **Note:** Due to reasons stated above, modifying its `dateFormat` property may leads to
    /// unexpected and surprising behavior.
    /// 
    /// If you want to use a custom `dateFormat`, the new format must be valid so that the formatter
    /// can convert the formatted string back to NSDate. And depending on the values of `rotatingInterval`
    /// and `expirationInterval`, the extracted NSDate should have enough precision.
    public let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd.HH-mm-ss-SSSS"
        return formatter
    }()
    
    public init(inDirectory directoryPath: String = defaultLogDirectoryPath(),
                formatter: LogFormatter = defaultFileDestinationFormatter(),
                theme: FileTheme? = nil,
                queue: DispatchQueue = DispatchQueue(label: "com.uncosmos.Logging.managed-file", qos: .background),
                rotatingInterval: TimeInterval = 24 * 60 * 60,
                maximumLogFileSize: UInt = 0,
                expirationInterval: TimeInterval = 7 * 24 * 60 * 60,
                maximumNumberOfLogFiles: Int = 0,
                maximumLogFilesDiskSpace: UInt = 0) {
        
        self.queue = queue
        
        self.formatter = formatter
        self.theme = theme
        self.directoryPath = directoryPath
        
        self.rotatingInterval = rotatingInterval
        self.maximumLogFileSize = maximumLogFileSize
        self.expirationInterval = expirationInterval
        self.maximumNumberOfLogFiles = maximumNumberOfLogFiles
        self.maximumLogFilesDiskSpace = maximumLogFilesDiskSpace
        
        prune()
    }
    
    /**
     Receive new log use specified parameters. You should not call this method directly.
     */
    public func receiveLog(of level: PriorityLevel, items: [String], separator: String, file: String, line: Int, function: String, date: Date) {
        // Make preparations.
        if currentFile == nil || rotateNeeded {
            rotateForcely()
            prune()
        }
        
        guard let fileStream = currentFile?.stream else {
            return print("<com.uncosmos.Logging>: Error receiving log: Cannot open file stream.")
        }
        
        // Produce the log message.
        var entry = formatter.formatComponents(level: level, items: items, separator: separator, file: file, line: line, function: function, date: date)
        if let theme = theme {
            entry = theme.colorizeEntry(entry, forLevel: level)
        }
        let log = formatter.formatEntry(entry)
        
        // Write log to file asynchronously.
        queue.async {
            let characters = log.UTF8String
            fputs(characters, fileStream)
            
            // Update current file size.
            let lengthInBytes = UInt(characters.count * MemoryLayout<CChar>.size)
            if self.currentFile != nil {
                self.currentFile!.info.fileSize += lengthInBytes
                for index in self.managedFileInfos.indices {
                    // The current file info should be at index 0.
                    if self.managedFileInfos[index].fileName == self.currentFile!.info.fileName {
                        self.managedFileInfos[index].fileSize += lengthInBytes
                        break
                    }
                }
            }
        }
    }
    
    /**
     Flush all queued log messages to the log file.
     */
    public func flush() {
        queue.sync()
        
        if let currentFileStream = currentFile?.stream {
            fflush(currentFileStream)
        }
    }
    
    /**
     Reindex the log directory.
     */
    public func reindex() {
        // Clear saved file informations.
        managedFileInfos.removeAll()
        managedFilesUsedDiskSpace = 0
        
        // Reindex.
        let fileManager = FileManager.default
        do {
            if !fileManager.fileExists(atPath: directoryPath) {
                try fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
            }
            
            let fileNames = try fileManager.contentsOfDirectory(atPath: directoryPath)
            
            managedFileInfos.reserveCapacity(fileNames.count)
            
            for fileName in fileNames {
                let filePath = makeFilePath(named: fileName)
                guard !fileManager.isDirectory(filePath) else {
                    continue
                }
                
                guard let creationDate = dateOfLogFile(named: fileName) else {
                    continue
                }
                
                let file = fopen(filePath.UTF8String, "r")
                let fileSize: UInt
                if file != nil {
                    fseek(file, 0, SEEK_END)
                    fileSize = UInt(ftell(file))
                    fclose(file)
                } else {
                    fileSize = 0
                }
                
                managedFilesUsedDiskSpace += fileSize
                let logFileInfo = FileInfo(fileSize: fileSize, fileName: fileName, creationDate: creationDate)
                managedFileInfos.append(logFileInfo)
            }
            
            managedFileInfos.sort { one, other in
                return one.creationDate.timeIntervalSinceReferenceDate > other.creationDate.timeIntervalSinceReferenceDate
            }
        } catch {
            if let delegate = delegate {
                delegate.managedFileDestination(self, didCatchError: error as NSError)
            } else {
                print("Error reindexing \(directoryPath): \(error).")
            }
        }
    }
    
    public func rotate() {
        rotateForcely()
        prune()
    }
    
    public func prune() {
        reindex()
        pruneForcely()
    }
    
    public func dateOfLogFile(named name: String) -> Date? {
        guard name.characters.count > 29 else {
            return nil
        }
        
        let extensionStartIndex = name.characters.index(name.endIndex, offsetBy: -4)
        guard name.substring(from: extensionStartIndex) == ".log" else {
            return nil
        }
        
        let dateStartIndex = name.characters.index(extensionStartIndex, offsetBy: -24)
        let dateString = name.substring(with: dateStartIndex..<extensionStartIndex)
        let prefixString = name.substring(to: name.characters.index(before: dateStartIndex))
        
        guard prefixString == staticLogFileNamePrefix() else {
            return nil
        }
        
        return dateFormatter.date(from: dateString)
    }

    deinit {
        queue.sync()
        
        if let currentFileStream = currentFile?.stream {
            fclose(currentFileStream)
        }
    }
    
    private var rotateNeeded: Bool {
        guard let currentFileInfo = currentFile?.info else {
            return false
        }
        
        // Check if we need to rotate.
        let rotatingIntervalExceeded = rotatingInterval > 0
            && -currentFileInfo.creationDate.timeIntervalSinceNow > rotatingInterval
        let fileSizeExceeded = maximumLogFileSize > 0
            && currentFileInfo.fileSize > maximumLogFileSize
        
        return rotatingIntervalExceeded || fileSizeExceeded
    }
    
    private var diskQuotaExceeded: Bool {
        return maximumLogFilesDiskSpace > 0 && managedFilesUsedDiskSpace > maximumLogFilesDiskSpace
    }
    
    private var numberOfLogFilesExceeded: Bool {
        return maximumNumberOfLogFiles > 0 && managedFileInfos.count > maximumNumberOfLogFiles
    }
    
    private func makeFilePath(named name: String) -> String {
        return (directoryPath as NSString).appendingPathComponent(name)
    }
    
    private func rotateForcely() {
        // If current log file is opened, flush then close it.
        if let currentFileStream = currentFile?.stream {
            queue.sync()
            fclose(currentFileStream)
        }
        
        let now = Date()
        let fileName = String(format: "%@.%@.log",
                              staticLogFileNamePrefix() as CVarArg,
                              dateFormatter.string(from: now) as CVarArg)
        let filePath = makeFilePath(named: fileName)
        let fileStream = fopen(filePath.UTF8String, "w")
        
        if let fileStream = fileStream {
            print("Rotating to new log file: \(fileName)")
            let fileInfo = FileInfo(fileSize: 0, fileName: fileName, creationDate: now)
            currentFile = (fileStream, fileInfo)
        } else {
            print("<com.uncosmos.Logging>: Failed to open log file \(filePath), errno: \(errno).")
        }
    }
    
    private func rotateIfNeeded() {
        if rotateNeeded {
            rotateForcely()
            reindex()
            pruneForcely()
        }
    }
    
    private func pruneForcely() {
        guard expirationInterval > 0 || maximumNumberOfLogFiles > 0 || maximumLogFilesDiskSpace > 0 else {
            // All limits are disabled, no need to prune.
            return
        }
        
        let fileManager = FileManager.default
        for (index, fileInfo) in managedFileInfos.enumerated().reversed() { // Starting from oldest log file.
            if let currentFileName = currentFile?.info.fileName , fileInfo.fileName == currentFileName {
                // Leave current log file untouched.
                break
            }
            
            let expired = expirationInterval > 0
                && -fileInfo.creationDate.timeIntervalSinceNow > expirationInterval
            
            if expired || numberOfLogFilesExceeded || diskQuotaExceeded {
                let filePath = makeFilePath(named: fileInfo.fileName)
                do {
                    try fileManager.removeItem(atPath: filePath)
                    print("Removed log file: \(fileInfo.fileName)")
                    managedFilesUsedDiskSpace -= fileInfo.fileSize
                    managedFileInfos.remove(at: index)
                } catch {
                    if let delegate = delegate {
                        delegate.managedFileDestination(self, didCatchError: error as NSError)
                    } else {
                        print("<com.uncosmos.Logging>: Error deleting file \(filePath): \(error).")
                    }
                }
            }
        }
    }
    
    public struct FileInfo {
        fileprivate var fileSize: UInt
        
        public let fileName: String
        public let creationDate: Date
    }
}

public protocol ManagedFileDestinationDelegate: class {
    func managedFileDestination(_ destination: ManagedFileDestination, shouldDeleteFileAtPath: String) -> Bool
    func managedFileDestination(_ destination: ManagedFileDestination, didCatchError: NSError)
}

private func staticLogFileNamePrefix() -> String {
    return App.identifier ?? App.name
}

private func defaultLogDirectoryPath() -> String {
    #if os(OSX)
        return App.ensuredLogsDirectoryPath
    #else // iOS, tvOS, watchOS
        return (App.ensuredLogsDirectoryPath as NSString).appendingPathComponent(App.identifier ?? App.name)
    #endif
}
