//
//  ChecksumGenerator.swift
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

struct MD5ChecksumContext: ChecksumContext {
    private var backingContext: CC_MD5_CTX
    
    init() {
        var context = CC_MD5_CTX()
        CC_MD5_Init(&context)
        self.backingContext = context
    }
    
    mutating func update(data: Data) {
        data.withUnsafeBytes {
            _ = CC_MD5_Update(&self.backingContext, $0.baseAddress, numericCast(data.count))
        }
    }
    
    mutating func finalize() -> Data {
        var digest: [UInt8] = Array(repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        _ = CC_MD5_Final(&digest, &self.backingContext)
        return Data(digest)
    }
}

struct SHA256ChecksumContext: ChecksumContext {
    private var backingContext: CC_SHA256_CTX
        
    init() {
        var context = CC_SHA256_CTX()
        CC_SHA256_Init(&context)
        self.backingContext = context
    }
    
    mutating func update(data: Data) {
        data.withUnsafeBytes {
            _ = CC_SHA256_Update(&self.backingContext, $0.baseAddress, numericCast(data.count))
        }
    }
    
    mutating func finalize() -> Data {
        var digest: [UInt8] = Array(repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = CC_SHA256_Final(&digest, &self.backingContext)
        return Data(digest)
    }
}

@objc
public enum ChecksumType: Int {
    case md5 = 0
    case sha256
    
    var contextType: ChecksumContext.Type {
        switch self {
        case .md5: return MD5ChecksumContext.self
        case .sha256: return SHA256ChecksumContext.self
        }
    }
}

struct ChecksumGenerator {
    let checksumType: ChecksumType
    
    func generateChecksum(
        forFileAt url: URL,
        progressHandler: (Double) -> Void
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
        
        progressHandler(0.0)
        
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
            progressHandler(Double(iteration) / Double(totalIterationCount))
        }
        
        progressHandler(1.0)
        
        return context.finalize()
    }
}
