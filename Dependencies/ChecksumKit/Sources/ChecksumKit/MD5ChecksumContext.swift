//
//  MD5ChecksumContext.swift
//  ChecksumKit
//

import CommonCrypto
import Foundation

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
