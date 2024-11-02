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
    
    public private(set) var files: [URL: Data] = [:]
    
    public init(files: [URL: Data] = [:]) {
        self.files = files
    }
    
    public init(data: Data) throws {
        guard let string = String(data: data, encoding: .utf8) else {
            throw Error.failedToDecodeString
        }
        
        let items = string.split(separator: /[\r\n]+/)
        
        for item in items {
            let match = item.wholeMatch(of: /([0-9a-fA-F]+)\s\s(.+)/)
            
            guard let match else {
                throw Error.invalidRow
            }
            
            guard let checksum = Data(hexString: String(match.output.1)) else {
                throw Error.invalidChecksum
            }
            
            let url = URL(fileURLWithPath: String(match.output.2))
            
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
