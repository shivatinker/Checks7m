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
    
    public private(set) var files: [String: Data] = [:]
    
    public init(files: [String: Data] = [:]) {
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
            
            self.files[String(match.output.2)] = checksum
        }
    }
    
    public func makeData() -> Data {
        var string = ""
            
        for (path, checksum) in self.files.sorted(using: KeyPathComparator(\.key)) {
            string += "\(checksum.hexString)  \(path)\n"
        }
        
        return string.data(using: .utf8)!
    }
    
    public mutating func add(file: String, checksum: Data) {
        self.files[file] = checksum
    }
    
    public func hasChecksum(for path: String) -> Bool {
        self.files.keys.contains(path)
    }
}
