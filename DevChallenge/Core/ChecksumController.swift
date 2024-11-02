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
        for files: [URL],
        type: ChecksumType,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let proxy = try self.makeConnection(progressHandler: progressHandler)
        
        let path = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Swift.Error>) in
            proxy.generateChecksumsFile(
                for: files.map { $0.path(percentEncoded: false) },
                outputURL: "/Users/shivatinker/stuff.sha256",
                type: .sha256
            ) { path, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let path else {
                    continuation.resume(throwing: Error("Failed to get path"))
                    return
                }
                
                continuation.resume(returning: path)
            }
        }
        
        return URL(filePath: path)
    }
    
    func validateChecksums(
        for files: [URL],
        checksumFileURL: URL,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async -> Result<Void, Swift.Error> {
        do {
            let proxy = try self.makeConnection(progressHandler: progressHandler)
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Swift.Error>) in
                proxy.validateChecksums(
                    for: files.map(\.path),
                    checksumFileURL: checksumFileURL.path
                ) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    }
                    else {
                        continuation.resume()
                    }
                }
            }
            
            return .success(())
        }
        catch {
            return .failure(error)
        }
    }
    
    private func makeConnection(
        progressHandler: @escaping @Sendable (Double) -> Void
    ) throws -> DevChallengeXPCProtocol {
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
        
        return proxy
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
