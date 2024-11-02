//
//  Utils.swift
//  ChecksumKit
//
//  Created by Andrii Zinoviev on 02.11.2024.
//

import Foundation

extension Data {
    public var hexString: String {
        self.map { String(format: "%02hhx", $0) }.joined()
    }

    public init?(hexString: String) {
        self.init(capacity: hexString.count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: hexString, range: NSRange(hexString.startIndex..., in: hexString)) { match, _, _ in
            let byteString = (hexString as NSString).substring(with: match!.range)
            let num = UInt8(byteString, radix: 16)!
            self.append(num)
        }
        
        guard self.count > 0 else { return nil }
    }
}

extension FileManager {
    public func isDirectory(url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        self.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }
}
