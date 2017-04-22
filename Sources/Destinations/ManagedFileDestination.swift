//
//  ManagedFileDestination.swift
//  Logging
//
//  Created by 锋炜 刘 on 16/8/21.
//  Copyright © 2016年 kAzec. All rights reserved.
//

import Dispatch
import Darwin.C.time

open class ManagedFileDestination: LogDestination {
    
    // MARK: - Immutable Properties
    
    /// The url to the directory where all the log files will be stored.
    ///
    /// This destination expects full control of all **files** in the main directory. All sub-directories, however will
    /// be ignored during the indexing process.
    public let mainDirectory: URL
    
    public let formatter: LogFormatter?
    public let queue: DispatchQueue?
    
    
    // MARK: - Quotas
    
    /// The longest period of time that the active logging file can be used.
    ///
    /// **Note:** A check will be performed when a new log entry arrives, in the following situations:
    /// 1. After this destination writes the log entry down.
    /// 2. When this value is found to be modifed.
    ///
    /// The active logging file will be rotated if the active logging file fails to pass the check.
    ///
    /// The default value is `24 * 60 * 60`, aka one day.
    ///
    /// Setting a value less or equal than zero will disable this quota.
    public var activeFileAgeQuota: TimeInterval {
        set {
            quotasLock.lock(); defer { quotasLock.unlock() }
            activeFileQuotas.ageQuota = newValue
            isActiveFileQuotasModified = true
        }
        
        get {
            return activeFileQuotas.ageQuota
        }
    }
    
    /// The maximum disk space(in bytes) that the active logging file can use.
    ///
    /// **Note:** A check will be performed alongside the check of the `activeFileAgeQuota`, see its description for
    /// details.
    ///
    /// Its default value is 0 and that disables this limit.
    public var activeFileSizeQuota: UInt64 {
        set {
            quotasLock.lock(); defer { quotasLock.unlock() }
            activeFileQuotas.sizeQuota = newValue
            isActiveFileQuotasModified = true
        }
        
        get {
            return activeFileQuotas.sizeQuota
        }
    }
    
    /// The longest period of time that a archived logging file can be kept.
    ///
    /// **Note:** A check will be performed on each archived logging file in the list when a new log entry arrives, in
    /// the following situations:
    /// 1. After the active logging is rotated. See description of `activeFileAgeQuota` for details.
    /// 2. When this value is found to be modified.
    ///
    /// The archived logging files which fail to pass the check will be removed by invoking the method 
    /// `removeArchivedFile(at:)`. You can override that method to perform customized removal.
    ///
    /// The default value is `7 * 24 * 60 * 60`, aka 7 days.
    ///
    /// Setting a value less or equal than zero will disable this quota.
    ///
    /// Setting a value less or equal than `activeFileAgeQuota` will cause the archived logging file to be removed
    /// immediately.
    public var archivedFileAgeQuota: TimeInterval {
        set {
            quotasLock.lock(); defer { quotasLock.unlock() }
            archivedFileQuotas.ageQuota = newValue
            isArchivedFileQuotasModified = true
        }
        
        get {
            return archivedFileQuotas.ageQuota
        }
    }
    
    /// The maximum number of archived logging files can be kept.
    ///
    /// **Note:** A check will be performed alongside the check of the `archivedFileAgeQuota`, see its description for
    /// details.
    ///
    /// The default value is 0, which disables this limit.
    public var archivedFilesCountQuota: UInt {
        set {
            quotasLock.lock(); defer { quotasLock.unlock() }
            archivedFileQuotas.countQuota = newValue
            isArchivedFileQuotasModified = true
        }
        
        get {
            return archivedFileQuotas.countQuota
        }
    }
    
    /// The maximum disk space(in bytes) that all the archived logging files can use.
    ///
    /// **Note:** A check will be performed alongside the check of the `archivedFileAgeQuota`, see its description for
    /// details.
    ///
    /// The default value is 0, which disables this limit.
    public var archivedFilesTotalSizeQuota: UInt64 {
        set {
            quotasLock.lock(); defer { quotasLock.unlock() }
            archivedFileQuotas.totalSizeQuota = newValue
            isArchivedFileQuotasModified = true
        }
        
        get {
            return archivedFileQuotas.totalSizeQuota
        }
    }
    
    private struct ActiveFileQuotas {
        
        var ageQuota: TimeInterval
        var sizeQuota: UInt64
    }
    
    private struct ArchivedFileQuotas {
        
        var ageQuota: TimeInterval
        var countQuota: UInt
        var totalSizeQuota: UInt64
    }
    
    /// Since quotas are typically written on the main thread and read on the destinaion's/logger's internal thread, a
    /// lock is needed to synchronize the access.
    private let quotasLock: NSLock
    
    private var isActiveFileQuotasModified: Bool = false
    private var isArchivedFileQuotasModified: Bool = false
    
    private var activeFileQuotas: ActiveFileQuotas
    private var archivedFileQuotas: ArchivedFileQuotas
    
    
    // MARK: - Internal State.
    
    private struct State {
        
        struct ActiveFile {
            
            struct OpenError : Error, CustomStringConvertible {
                let url: URL
                let errno: Int32
                
                var description: String {
                    return "Failed to create or open file at \(url), errno(\(errno))."
                }
            }
            
            let url: URL
            let handle: FileHandle
            let creationDate: Date
            
            var size: UInt64 {
                return handle.offsetInFile
            }
            
            var age: TimeInterval {
                return -creationDate.timeIntervalSinceNow
            }
            
            init(url: URL, creationDate: Date) throws {
                let fileDescriptor = open(url.path, O_WRONLY | O_CREAT)
                
                guard fileDescriptor >= 0 else {
                    throw OpenError(url: url, errno: errno)
                }
                
                self.url = url
                self.handle = FileHandle(fileDescriptor: fileDescriptor)
                self.creationDate = creationDate
            }
            
            init(in directory: URL) throws {
                let creationDate = Date()
                let url = directory.appendingPathComponent(creationDate.logFileName, isDirectory: false)
                try self.init(url: url, creationDate: creationDate)
            }
        }
        
        struct ArchivedFile {
            let url: URL
            let size: UInt64
            let creationDate: Date
            
            var age: TimeInterval {
                return -creationDate.timeIntervalSinceNow
            }
        }

        private(set) var activeFile: ActiveFile
        private(set) var archivedFiles: [ArchivedFile]
        private(set) var archivedFilesCount: UInt
        private(set) var archivedFilesTotalSize: UInt64
        
        mutating func shouldRotateActiveFileWithQuotas(_ quotas: ActiveFileQuotas) -> Bool {
            return !(activeFile.age.meetsQuota(quotas.ageQuota) && activeFile.size.meetsQuota(quotas.sizeQuota))
        }
        
        mutating func rotate(createNewActiveFileIn directory: URL) throws {
            let newActiveFile = try ActiveFile(in: directory)
            let newArchivedFile = ArchivedFile(url: activeFile.url, size: activeFile.handle.offsetInFile,
                                               creationDate: activeFile.creationDate)
            
            archivedFiles.append(newArchivedFile)
            archivedFilesCount += 1
            archivedFilesTotalSize += newArchivedFile.size
            
            activeFile = newActiveFile
        }
        
        mutating func applyArchivedFileQuotas(_ quotas: ArchivedFileQuotas, removal: (URL) throws -> ()) rethrows {
            guard !archivedFiles.isEmpty else {
                return
            }
            
            // The archived files array is sorted by creation date from oldest to newest.
            var removedFilesCount: UInt = 0
            var removedFilesTotalSize: UInt64 = 0
                
            for file in archivedFiles {
                if !(file.age.meetsQuota(quotas.ageQuota) && archivedFilesCount.meetsQuota(quotas.countQuota)
                    && archivedFilesTotalSize.meetsQuota(quotas.totalSizeQuota)) {
                    
                    try removal(file.url)
                    
                    removedFilesCount += 1
                    removedFilesTotalSize += file.size
                    
                    continue
                } else {
                    // All quotas are met, break out to perform actual removal.
                    break
                }
            }
            
            archivedFiles.removeFirst(Int(removedFilesCount))
            archivedFilesCount -= removedFilesCount
            archivedFilesTotalSize -= removedFilesTotalSize
        }
        
        /// Create a brand new empty state.
        static func empty(in directory: URL) throws -> State {
            return try State(activeFile: ActiveFile(in: directory), archivedFiles: [], archivedFilesCount: 0,
                                 archivedFilesTotalSize: 0)
        }
    }
    
    // Mutable internal state
    private var state: State!
    
    
    // MARK: - Public methods.
    
    public init(mainDirectory: URL = ManagedFileDestination.makeDefaultMainDirectoryURL(), formatter: LogFormatter?,
                queue: DispatchQueue? = DispatchQueue(label: "com.uncosmos.Logging.managed-file", qos: .background),
                activeFileAgeQuota: TimeInterval = 24 * 60 * 60, activeFileSizeQuota: UInt64 = 0,
                archivedFileAgeQuota: TimeInterval = 7 * 24 * 60 * 60, archivedFilesCountQuota: UInt = 0,
                archivedFilesTotalSizeQuota: UInt64 = 0) {
        
        self.mainDirectory = mainDirectory
        self.formatter = formatter
        self.queue = queue
        
        quotasLock = NSLock()
        quotasLock.name = "com.uncosmos.Logging.managed-file-quotas"
        
        activeFileQuotas = ActiveFileQuotas(ageQuota: activeFileAgeQuota, sizeQuota: activeFileSizeQuota)
        archivedFileQuotas = ArchivedFileQuotas(ageQuota: archivedFileAgeQuota, countQuota: archivedFilesCountQuota,
                                                totalSizeQuota: archivedFilesTotalSizeQuota)
    }
    
    public func initialize() {
        // Read quotas.
        quotasLock.lock()
        let activeFileQuotas = self.activeFileQuotas
        let archivedFileQuotas = self.archivedFileQuotas
        
        isActiveFileQuotasModified = false
        isArchivedFileQuotasModified = false
        quotasLock.unlock()
        
        // Reindex main directory.
        do {
            // Perform a shallow search on the main directory and cache the resulting urls with some properties.
            let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .fileSizeKey, .creationDateKey]
            let contents = try FileManager.default.contentsOfDirectory(at: mainDirectory,
                                                                       includingPropertiesForKeys: Array(resourceKeys),
                                                                       options: .skipsHiddenFiles)
            
            if !contents.isEmpty {
                var archivedFiles: [State.ArchivedFile] = []
                var archivedFilesCount: UInt = 0
                var archivedFilesTotalSize: UInt64 = 0
                
                for var fileURL in contents {
                    // Retrieve then purge cached resource values.
                    let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)
                    fileURL.removeAllCachedResourceValues()
                    
                    // Skip directories.
                    guard !resourceValues.isDirectory! else { continue }
                    
                    let fileSize = UInt64(resourceValues.fileSize!)
                    let creationDate = resourceValues.creationDate!
                    
                    // Check if the file is too old.
                    let age = -creationDate.timeIntervalSinceNow
                    if age.meetsQuota(archivedFileQuotas.ageQuota) {
                        let file =  State.ArchivedFile(url: fileURL, size: fileSize, creationDate: creationDate)
                        archivedFilesTotalSize += fileSize
                        archivedFilesCount += 1
                        archivedFiles.append(file)
                    } else {
                        try removeArchivedFile(at: fileURL)
                        continue
                    }
                }
                
                if archivedFiles.isEmpty {
                    state = try .empty(in: mainDirectory)
                    return
                }
                
                // Sort the file infos by creation date from oldest to newest.
                archivedFiles.sort {
                    $0.creationDate < $1.creationDate
                }
                
                // Create the active file.
                let activeFile: State.ActiveFile
                
                // Check if we should continue to use the most recent log file.
                let newestArchivedFile = archivedFiles.last!
                if newestArchivedFile.age.meetsQuota(activeFileQuotas.ageQuota)
                    && newestArchivedFile.age.meetsQuota(archivedFileQuotas.ageQuota)
                    && newestArchivedFile.size.meetsQuota(activeFileQuotas.sizeQuota) {
                    
                    archivedFiles.removeLast()
                    archivedFilesTotalSize -= newestArchivedFile.size
                    archivedFilesCount -= 1
                    
                    activeFile = try .init(url: newestArchivedFile.url, creationDate: newestArchivedFile.creationDate)
                } else {
                    activeFile = try .init(in: mainDirectory)
                }
                
                // Create the state and apply archived file quotas.
                state = State(activeFile: activeFile, archivedFiles: archivedFiles,
                              archivedFilesCount: archivedFilesCount,
                              archivedFilesTotalSize: archivedFilesTotalSize)
                
                try state.applyArchivedFileQuotas(archivedFileQuotas, removal: removeArchivedFile(at:))
            }
        } catch {
            print("<com.uncosmos.Logging> Managed file destination unable to initialize due to error: \"\(error)\"")
            return
        }
    }
    
    public func deinitialize() {
        if let activeFileHandle = state?.activeFile.handle {
            state = nil
            activeFileHandle.synchronizeFile()
            activeFileHandle.closeFile()
        }
    }
    
    public func write(_ entry: LogEntry) {
        guard state != nil else {
            return
        }
        
        quotasLock.lock()
        let activeFileQuotas = self.activeFileQuotas
        let archivedFileQuotas = self.archivedFileQuotas
        
        let isActiveFileQuotasModified = self.isActiveFileQuotasModified
        let isArchivedFileQuotasModified = self.isArchivedFileQuotasModified
        
        self.isActiveFileQuotasModified = false
        self.isArchivedFileQuotasModified = false
        quotasLock.unlock()
        
        do {
            var didRotate = false
            
            // Maybe rotate active file if the associated quotas have been modified.
            if isActiveFileQuotasModified && state.shouldRotateActiveFileWithQuotas(activeFileQuotas) {
                try state.rotate(createNewActiveFileIn: mainDirectory)
                didRotate = true
            }
            
            // Write data to active file handle.
            if let data = entry.content.data(using: .utf8) {
                state.activeFile.handle.write(data)
                
                if !(state.activeFile.size.meetsQuota(activeFileQuotas.sizeQuota)
                    && state.activeFile.age.meetsQuota(activeFileQuotas.ageQuota)) {
                    
                    try state.rotate(createNewActiveFileIn: mainDirectory)
                    didRotate = true
                }
            }
            
            // Maybe remove outdated archived files if either we performed a rotation before or the associated quotas 
            // have been modified.
            if didRotate || isArchivedFileQuotasModified {
                try state.applyArchivedFileQuotas(archivedFileQuotas, removal: removeArchivedFile(at:))
            }
        } catch {
            print("<com.uncosmos.Logging> Managed file destination encountered error: \"\(error)\", in \(#function)")
            state = nil
        }
    }
    
    public func synchronize() {
        state?.activeFile.handle.synchronizeFile()
    }
    
    /// Remove the archived logging file from the main directory at the given url.
    open func removeArchivedFile(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
    
    private static func makeDefaultMainDirectoryURL() -> URL {
        #if os(macOS)
            return App.makeLogsDirectory().appendingPathComponent(App.loggingIdentifier, isDirectory: true)
        #else
            return App.makeLogsDirectory()
        #endif
    }
}


extension TimeInterval {
    func meetsQuota(_ quota: TimeInterval) -> Bool {
        return quota <= 0 ? true : self <= quota
    }
}

extension UInt {
    func meetsQuota(_ quota: UInt) -> Bool {
        return quota == 0 ? true : self <= quota
    }
}

extension UInt64 {
    func meetsQuota(_ quota: UInt64) -> Bool {
        return quota == 0 ? true : self <= quota
    }
}
