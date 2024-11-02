//
//  ChecksumGenerator.swift
//  ChecksumKit
//
//  Created by Andrii Zinoviev on 02.11.2024.
//

import Foundation

public struct ChecksumGenerator {
    public let checksumType: ChecksumType
    
    public init(checksumType: ChecksumType) {
        self.checksumType = checksumType
    }
    
    public func generateChecksums(for files: [URL]) throws -> ChecksumFile {
        let generator = FileChecksumGenerator(checksumType: self.checksumType)
        var result = ChecksumFile()
        
        try self.processFiles(at: files) { url in
            let checksum = try generator.generateChecksum(forFileAt: url)
            result.add(file: url, checksum: checksum)
        }
        
        return result
    }
    
    private func processFiles(at urls: [URL], fileHandler: (URL) throws -> Void) rethrows {
        let fileManager = FileManager.default

        for url in urls {
            // Use a file enumerator to recursively traverse directories
            if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil) {
                for case let fileURL as URL in enumerator {
                    var isDirectory: ObjCBool = false
                    if fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory), !isDirectory.boolValue {
                        // Call the fileHandler for each file
                        try fileHandler(fileURL)
                    }
                }
            }
        }
    }
}
