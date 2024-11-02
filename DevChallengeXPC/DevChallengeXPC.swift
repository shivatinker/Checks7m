//
//  DevChallengeXPC.swift
//  DevChallengeXPC
//
//  Created by Andrii Zinoviev on 01.11.2024.
//

import ChecksumKit
import Foundation

@objc public protocol DevChallengeXPCListener {
    func handleProgress(_ progress: Double)
}

/// The protocol that this service will vend as its API. This protocol will also need to be visible to the process hosting the service.
@objc public protocol DevChallengeXPCProtocol {
    func generateChecksumsFile(
        for files: [String],
        outputDirectoryPath: String,
        type: ChecksumType,
        completionHandler: @escaping (String?, Error?) -> Void
    )
    
    func validateChecksums(
        for files: [String],
        checksumFilePath: String,
        completionHandler: @escaping (Error?) -> Void
    )
    
    func cancelAllTasks()
}

/// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
class DevChallengeXPC: NSObject, DevChallengeXPCProtocol {
    private var tasks: Set<Task<Void, Never>> = []
    
    unowned var connection: NSXPCConnection!
    
    func cancelAllTasks() {
        for task in self.tasks {
            task.cancel()
        }
        
        self.tasks.removeAll()
    }
    
    func generateChecksumsFile(
        for files: [String],
        outputDirectoryPath: String,
        type: ChecksumType,
        completionHandler: @escaping (String?, Error?) -> Void
    ) {
        let task = Task {
            do {
                let file = try self.generateChecksums(for: files, type: type)
                
                let data = file.makeData()
                
                try FileManager.default.createDirectory(atPath: outputDirectoryPath, withIntermediateDirectories: true)
                let outputURL = URL(filePath: outputDirectoryPath).appending(path: "checksum.\(type.fileExtension)")
                try data.write(to: outputURL)
                completionHandler(outputURL.path, nil)
            }
            catch {
                completionHandler(nil, error)
            }
        }
        
        self.tasks.insert(task)
    }
    
    func validateChecksums(
        for files: [String],
        checksumFilePath: String,
        completionHandler: @escaping (Error?) -> Void
    ) {
        let task = Task {
            do {
                let listener = self.connection.remoteObjectProxy as! DevChallengeXPCListener
                
                let validator = ChecksumValidator()
                try validator.validate(
                    files: files,
                    checksumFilePath: checksumFilePath,
                    progressHandler: {
                        listener.handleProgress($0)
                    }
                )
                
                completionHandler(nil)
            }
            catch {
                completionHandler(error)
            }
        }
        
        self.tasks.insert(task)
    }
    
    private func generateChecksums(
        for files: [String],
        type: ChecksumType
    ) throws -> ChecksumFile {
        let generator = ChecksumGenerator(checksumType: type)
        let listener = self.connection.remoteObjectProxy as! DevChallengeXPCListener
        
        return try generator.generateChecksums(for: files.map { URL(filePath: $0) }) { progress in
            listener.handleProgress(progress)
        }
    }
}
