//
//  FileChecksumGenerator.swift
//  DevChallenge
//
//  Created by Andrii Zinoviev on 02.11.2024.
//

import CommonCrypto
import Foundation

protocol ChecksumContext {
    init()
    mutating func update(data: Data)
    mutating func finalize() -> Data
}

@objc
public enum ChecksumType: Int, CaseIterable, Sendable {
    case md5 = 0
    case sha256
    
    var contextType: ChecksumContext.Type {
        switch self {
        case .md5: return MD5ChecksumContext.self
        case .sha256: return SHA256ChecksumContext.self
        }
    }
    
    public var fileExtension: String {
        switch self {
        case .md5: return "md5"
        case .sha256: return "sha256"
        }
    }
}

public struct FileChecksumGenerator {
    public let checksumType: ChecksumType
    
    public init(checksumType: ChecksumType) {
        self.checksumType = checksumType
    }
    
    public func generateChecksum(
        forFileAt url: URL,
        progressHandler: ((Double) -> Void)? = nil
    ) throws -> Data {
        let bufferSize = 1024 * 1024
        
        let file = try FileHandle(forReadingFrom: url)
        
        let fileSize = try FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))[.size] as! UInt64
        
        let totalIterationCount = Int(fileSize) / bufferSize + 1
        var iteration = 0
        
        defer {
            do {
                try file.close()
            }
            catch {
                print("Error closing file: \(error)")
            }
        }
        
        var context = self.checksumType.contextType.init()
        
        progressHandler?(0.0)
        
        while true {
            let shouldBreak = autoreleasepool {
                let data = file.readData(ofLength: bufferSize)

                if data.isEmpty {
                    return true
                }
                
                context.update(data: data)
                return false
            }
            
            if shouldBreak {
                break
            }
            
            iteration += 1
            progressHandler?(Double(iteration) / Double(totalIterationCount))
        }
        
        progressHandler?(1.0)
        
        return context.finalize()
    }
}
