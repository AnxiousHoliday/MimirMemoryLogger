//
//  MimirMemoryLogger.swift
//  Anghami Release
//
//  Created by Amer Eid on 9/24/20.
//  Copyright © 2020 Anghami. All rights reserved.
//

import UIKit

public class MimirMemoryLogger {
    private static var isLoggingMemory = false
    public static var verbose = true
    public static var maxNumberOfSnapshots = 5
    
    @objc public static func getSavedSnapshots() -> [URL]? {
        guard let memorySnapshotFiles = getSnapshotFiles() else {
            log("MimirMemoryLogger: Getting saved snapshots failed because no snapshots were found")
            return nil
        }
        return memorySnapshotFiles.map { (memoryLogFile) -> URL in
            return memoryLogFile.filePathURL
        }
    }
    
    @objc public static func saveCurrentSnapshotToFile(completion: ((_ fileURL: URL?)->(Void))?) {
        if isLoggingMemory {
            log("MimirMemoryLogger: Failed to take heap snapshot and save it because it is already being done in progress")
            completion?(nil)
            return
        }
        isLoggingMemory = true
        let saveCurrentSnapshotToFileTimer = ParkBenchTimer()
        createDirectoryIfNecessary()
        guard let folderTargetURL = getLoggersFolderDirectory() else {
            completion?(nil)
            return
        }
        autoreleasepool {
            let takingHeapSnapshotTimer = ParkBenchTimer()
            log("MimirMemoryLogger: Started taking heap snapshot")
            let snapshot = HeapStackInspector.heapSnapshot()
            log("MimirMemoryLogger: Finished taking heap snapshot, duration -> \(takingHeapSnapshotTimer.stop()) secs")
            isLoggingMemory = false
            do {
                log("MimirMemoryLogger: Started saving heap snapshot to disk")
                let jsonData = try JSONSerialization.data(withJSONObject: snapshot as Any)
                let jsonFileTarget = folderTargetURL.appendingPathComponent("\(Date().timeIntervalSince1970).json")
                FileManager.default.createFile(atPath: jsonFileTarget.path, contents: jsonData, attributes: nil)
                log("MimirMemoryLogger: Finished saving heap snapshot to disk, location -> \(jsonFileTarget.absoluteURL)")
                deleteOldestLogFileIfNecessary()
                log("MimirMemoryLogger: Total duration (taking heap snapshot + saving to disk) -> \(saveCurrentSnapshotToFileTimer.stop()) sec")
                completion?(jsonFileTarget)
            } catch let error as NSError {
                log("MimirMemoryLogger: Failed to write heap snapshot to disk -> \(error.localizedDescription)")
                completion?(nil)
            }
        }
    }
    
    private static func getLoggersFolderDirectory() -> URL? {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("MimirMemoryLogFiles")
    }
    
    private static func createDirectoryIfNecessary() {
        guard let getLoggersFolderDirectory = getLoggersFolderDirectory() else { return }
        if FileManager.default.fileExists(atPath: getLoggersFolderDirectory.path) == false {
            // Create the directory since it doesnt exist
            do {
                try FileManager.default.createDirectory(atPath: getLoggersFolderDirectory.path, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                log("MimirMemoryLogger: Failed while creating directory -> \(error.localizedDescription)")
            }
        }
    }
    
    private static func deleteOldestLogFileIfNecessary() {
        guard var memorySnapshotFiles = getSnapshotFiles() else { return }
        do {
            if memorySnapshotFiles.count > maxNumberOfSnapshots {
                // start deleting old logs files
                memorySnapshotFiles.sort { (memoryLogFile1, memoryLogFile2) -> Bool in
                    return memoryLogFile1.dateCreated > memoryLogFile2.dateCreated
                }
                while memorySnapshotFiles.count > maxNumberOfSnapshots {
                    let lastSnapshotFile = memorySnapshotFiles.removeLast()
                    try FileManager.default.removeItem(at: lastSnapshotFile.filePathURL)
                }
            }
        } catch let error as NSError {
            log("MimirMemoryLogger: Failed while trying to delete oldest log files -> \(error.localizedDescription)")
        }
    }
    
    private static func getSnapshotFiles() -> [MemoryLogFile]? {
        guard let loggersFolderDirectory = getLoggersFolderDirectory() else { return nil }
        do {
            let dirContents = try FileManager.default.contentsOfDirectory(atPath: loggersFolderDirectory.path)
            var logFiles = [MemoryLogFile]()
            for path in dirContents {
                if path.hasSuffix(".json") == false {
                    // ignore non json files
                    continue
                }
                let fullPathURL = loggersFolderDirectory.appendingPathComponent(path)
                guard let createdDate = try FileManager.default.attributesOfItem(atPath: fullPathURL.path)[FileAttributeKey(rawValue: "NSFileCreationDate")] as? Date else {
                    continue
                }
                let memoryLogFile = MemoryLogFile(filePathURL: fullPathURL, dateCreated: createdDate)
                logFiles.append(memoryLogFile)
            }
            return logFiles
        } catch let error as NSError {
            log("MimirMemoryLogger: Failed trying to fetch snapshot files: \(error.localizedDescription)")
            return nil
        }
    }
    
    private static func log(_ text: @escaping @autoclosure () -> Any?) {
        if verbose {
            print(text() ?? "")
        }
    }
}
class ParkBenchTimer {
    let startTime:CFAbsoluteTime
    var endTime:CFAbsoluteTime?

    init() {
        startTime = CFAbsoluteTimeGetCurrent()
    }

    func stop() -> CFAbsoluteTime {
        endTime = CFAbsoluteTimeGetCurrent()
        return duration!
    }

    var duration:CFAbsoluteTime? {
        if let endTime = endTime {
            return endTime - startTime
        } else {
            return nil
        }
    }
}

fileprivate struct MemoryLogFile {
    let filePathURL: URL
    let dateCreated: Date
}
