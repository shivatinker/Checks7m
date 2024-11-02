//
//  SHA256ChecksumContext.swift
//  ChecksumKit
//
//  Created by Andrii Zinoviev on 02.11.2024.
//

import CommonCrypto
import Foundation

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
