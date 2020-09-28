//
//  MimirMemoryLogger.swift
//  Anghami Release
//
//  Created by Amer Eid on 9/24/20.
//  Copyright © 2020 Anghami. All rights reserved.
//

import UIKit

class MimirMemoryLogger: NSObject {
    @objc public static func getSavedSnapshots() -> [URL]? {
        guard let memorySnapshotFiles = getSnapshotFiles() else {
            print("MimirMemoryLogger no snapshots found")
            return nil
        }
        if let loggersFolderDirectory = getLoggersFolderDirectory() {
            // print out logs directory just in cas
            print("MimirMemoryLogger folder location: \(loggersFolderDirectory.absoluteURL)")
        }
        return memorySnapshotFiles.map { (memoryLogFile) -> URL in
            return memoryLogFile.filePathURL
        }
    }
    
    @objc public static func saveCurrentSnapshotToFile(completion: ((_ fileURL: URL?)->(Void))?) {
        let start = CFAbsoluteTimeGetCurrent()
        createDirectoryIfNecessary()
        guard let folderTargetURL = getLoggersFolderDirectory() else {
            completion?(nil)
            return
        }
        let snapshot = HeapStackInspector.heapSnapshot()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: snapshot as Any)
            let jsonFileTarget = folderTargetURL.appendingPathComponent("\(Date().timeIntervalSince1970).json")
            FileManager.default.createFile(atPath: jsonFileTarget.path, contents: jsonData, attributes: nil)
            print("MimirMemoryLogger new snapshot taken -> location: \(jsonFileTarget.absoluteURL)")
            deleteOldestLogFileIfNecessary()
            let diff = CFAbsoluteTimeGetCurrent() - start
            print("MimirMemoryLogger: saveCurrentSnapshotToFile Took \(diff) seconds")
            completion?(jsonFileTarget)
        } catch let error as NSError {
            print("MimirMemoryLogger: creating json: \(error.localizedDescription)")
            completion?(nil)
        }
    }
    
    private static func getLoggersFolderDirectory() -> URL? {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("MemoryLogFiles")
    }
    
    private static func createDirectoryIfNecessary() {
        guard let getLoggersFolderDirectory = getLoggersFolderDirectory() else { return }
        if FileManager.default.fileExists(atPath: getLoggersFolderDirectory.path) == false {
            // Create the directory since it doesnt exist
            do {
                try FileManager.default.createDirectory(atPath: getLoggersFolderDirectory.path, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                print("MimirMemoryLogger: Error creating directory: \(error.localizedDescription)")
            }
        }
    }
    
    private static func deleteOldestLogFileIfNecessary() {
        let start = CFAbsoluteTimeGetCurrent()
        guard var memorySnapshotFiles = getSnapshotFiles() else { return }
        do {
            if memorySnapshotFiles.count > 5 {
                // start deleting old logs files
                memorySnapshotFiles.sort { (memoryLogFile1, memoryLogFile2) -> Bool in
                    return memoryLogFile1.dateCreated > memoryLogFile2.dateCreated
                }
                while memorySnapshotFiles.count > 5 {
                    let lastSnapshotFile = memorySnapshotFiles.removeLast()
                    try FileManager.default.removeItem(at: lastSnapshotFile.filePathURL)
                }
                let diff = CFAbsoluteTimeGetCurrent() - start
                print("MimirMemoryLogger: deleteOldestLogFileIfNecessary Took \(diff) seconds")
            }
        } catch let error as NSError {
            print("MimirMemoryLogger: Error in deleteOldestLogFileIfNecessary: \(error.localizedDescription)")
        }
    }
    
    private static func getSnapshotFiles() -> [MemoryLogFile]? {
        let start = CFAbsoluteTimeGetCurrent()
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
            let diff = CFAbsoluteTimeGetCurrent() - start
            print("MimirMemoryLogger: getSnapshotFiles Took \(diff) seconds")
            return logFiles
        } catch let error as NSError {
            print("MimirMemoryLogger: Error in deleteOldestLogFileIfNecessary: \(error.localizedDescription)")
            return nil
        }
    }
}

fileprivate struct MemoryLogFile {
    let filePathURL: URL
    let dateCreated: Date
}
