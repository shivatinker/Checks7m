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
        outputURL: String,
        type: ChecksumType,
        completionHandler: @escaping (String?, Error?) -> Void
    )
    
    func validateChecksums(
        for files: [String],
        checksumFileURL: String,
        completionHandler: @escaping (Error?) -> Void
    )
}

/// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
class DevChallengeXPC: NSObject, DevChallengeXPCProtocol {
    unowned var connection: NSXPCConnection!
    
    func generateChecksumsFile(
        for files: [String],
        outputURL: String,
        type: ChecksumType,
        completionHandler: @escaping (String?, Error?) -> Void
    ) {
        do {
            let file = try self.generateChecksums(for: files, type: type)
            
            let data = file.makeData()
            try data.write(to: URL(filePath: outputURL))
            completionHandler(outputURL, nil)
        }
        catch {
            completionHandler(nil, error)
        }
    }
    
    func validateChecksums(
        for files: [String],
        checksumFileURL: String,
        completionHandler: @escaping (Error?) -> Void
    ) {
        do {
            let listener = self.connection.remoteObjectProxy as! DevChallengeXPCListener
            
            let validator = ChecksumValidator()
            try validator.validate(
                files: files,
                checksumFilePath: checksumFileURL,
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
