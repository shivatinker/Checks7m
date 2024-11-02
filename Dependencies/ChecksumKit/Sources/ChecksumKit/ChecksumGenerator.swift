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
    
    public func generateChecksums(
        for files: [URL],
        progressHandler: ((Double) -> Void)?
    ) throws -> ChecksumFile {
        let generator = FileChecksumGenerator(checksumType: self.checksumType)
        var result = ChecksumFile()
        
        var totalUnitCount: Double = 0
        
        self.processFiles(at: files) { _ in
            totalUnitCount += 1
        }
        
        var completedUnitCount = 0
        
        try self.processFiles(at: files) { url in
            defer {
                completedUnitCount += 1
                progressHandler?(Double(completedUnitCount) / totalUnitCount)
            }
            
            if result.hasChecksum(for: url) {
                print("Skipping file \(url) because it has already been processed.")
                return
            }
            
            let checksum = try generator.generateChecksum(forFileAt: url) { progress in
                progressHandler?((Double(completedUnitCount) + progress) / totalUnitCount)
            }
            
            result.add(file: url, checksum: checksum)
        }
        
        return result
    }
    
    private func processFiles(at urls: [URL], fileHandler: (URL) throws -> Void) rethrows {
        let fileManager = FileManager.default

        for url in urls {
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
            
            if isDirectory.boolValue {
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
            else {
                try fileHandler(url)
            }
        }
    }
}
