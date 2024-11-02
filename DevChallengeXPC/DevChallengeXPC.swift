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
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        let generator = ChecksumGenerator(checksumType: type)
        
        do {
            let file = try generator.generateChecksums(for: files.map { URL(filePath: $0) })
            let data = file.makeData()
            try data.write(to: URL(filePath: outputURL))
            completionHandler(nil)
        }
        catch {
            completionHandler(error)
        }
    }
}
