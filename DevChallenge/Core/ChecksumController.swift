//
//  ChecksumController.swift
//  DevChallenge
//
//  Created by Andrii Zinoviev on 02.11.2024.
//

import ChecksumKit
import DevChallengeXPC
import Foundation

actor ChecksumController {
    struct Error: Swift.Error {
        let description: String
        
        init(_ description: String) {
            self.description = description
        }
    }
    
    init() {}
    
    func generateChecksum(
        forFileAt url: URL,
        type: ChecksumType,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> Data {
        let connectionToService = NSXPCConnection(serviceName: "com.shivatinker.DevChallengeXPC")
        connectionToService.remoteObjectInterface = NSXPCInterface(with: DevChallengeXPCProtocol.self)
        connectionToService.exportedInterface = NSXPCInterface(with: DevChallengeXPCListener.self)
        
        connectionToService.exportedObject = ListenerImpl {
            progressHandler($0)
        }
        
        connectionToService.resume()
        
        guard let proxy = connectionToService.remoteObjectProxy as? DevChallengeXPCProtocol else {
            throw Error("Failed to get remote object proxy")
        }
        
        let data = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Swift.Error>) in
            proxy.processFile(at: url, type: type) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let data else {
                    continuation.resume(throwing: Error("Expected data to be present"))
                    return
                }
                
                continuation.resume(returning: data)
            }
        }
        
        return data
    }
}

@objc
private final class ListenerImpl: NSObject, DevChallengeXPCListener {
    let progressHandler: (Double) -> Void
    
    init(progressHandler: @escaping (Double) -> Void) {
        self.progressHandler = progressHandler
        super.init()
    }
    
    func handleProgress(_ progress: Double) {
        self.progressHandler(progress)
    }
}
