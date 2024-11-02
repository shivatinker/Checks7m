//
//  DevChallengeXPC.swift
//  DevChallengeXPC
//
//  Created by Andrii Zinoviev on 01.11.2024.
//

import Foundation

@objc public protocol Listener {
    func handleProgress(_ progress: Double)
}

/// The protocol that this service will vend as its API. This protocol will also need to be visible to the process hosting the service.
@objc public protocol DevChallengeXPCProtocol {
    func processFile(
        at url: URL,
        type: ChecksumType,
        completionHandler: @escaping (Data?, Error?) -> Void
    )
}

/// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
class DevChallengeXPC: NSObject, DevChallengeXPCProtocol {
    unowned var connection: NSXPCConnection!
    
    func processFile(
        at url: URL,
        type: ChecksumType,
        completionHandler: @escaping (Data?, Error?) -> Void
    ) {
        let listener = self.connection.remoteObjectProxy as! Listener
        
        do {
            let generator = ChecksumGenerator(checksumType: type)
            
            let checksum = try generator.generateChecksum(
                forFileAt: url,
                progressHandler: {
                    listener.handleProgress($0)
                }
            )
            
            completionHandler(checksum, nil)
        }
        catch {
            completionHandler(nil, error)
        }
    }
}
