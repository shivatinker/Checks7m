//
//  ChecksumFile.swift
//  DevChallenge
//
//  Created by Andrii Zinoviev on 02.11.2024.
//

import Foundation

public struct ChecksumFile {
    enum Error: Swift.Error {
        case failedToDecodeString
        case invalidRow
        case invalidChecksum
    }
    
    private var files: [URL: Data] = [:]
    
    public init(files: [URL: Data] = [:]) {
        self.files = files
    }
    
    public init(data: Data) throws {
        guard let string = String(data: data, encoding: .utf8) else {
            throw Error.failedToDecodeString
        }
        
        let items = string.split(separator: /\n+/)
        
        for item in items {
            let parts = item.split(separator: /\s+/)
            
            guard parts.count == 2 else {
                throw Error.invalidRow
            }
            
            guard let checksum = Data(hexString: String(parts[0])) else {
                throw Error.invalidChecksum
            }
            
            let url = URL(fileURLWithPath: String(parts[1]))
            
            self.files[url] = checksum
        }
    }
    
    public func makeData() -> Data {
        var string = ""
            
        for (url, checksum) in self.files.sorted(using: KeyPathComparator(\.key.absoluteString)) {
            string += "\(checksum.hexString)  \(url.path(percentEncoded: false))\n"
        }
        
        return string.data(using: .utf8)!
    }
    
    public mutating func add(file: URL, checksum: Data) {
        self.files[file] = checksum
    }
    
    public func hasChecksum(for file: URL) -> Bool {
        self.files.keys.contains(file)
    }
}
