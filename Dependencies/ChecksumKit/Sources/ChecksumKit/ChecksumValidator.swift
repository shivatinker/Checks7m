//
//  ChecksumValidator.swift
//  ChecksumKit
//
//  Created by Andrii Zinoviev on 02.11.2024.
//

import Foundation

public struct ChecksumValidator {
    struct Error: Swift.Error {
        let description: String
        
        init(_ description: String) {
            self.description = description
        }
    }
    
    public init() {}
    
    public func validate(
        files: [String],
        checksumFilePath: String,
        progressHandler: ((Double) -> Void)? = nil
    ) throws {
        let type = try self.checksumType(path: checksumFilePath)
        
        let expectedChecksums = try ChecksumFile(data: try Data(contentsOf: URL(filePath: checksumFilePath)))
        
        let generator = ChecksumGenerator(checksumType: type)
        
        let checksums = try generator.generateChecksums(
            for: files.map { URL(filePath: $0) },
            progressHandler: progressHandler
        )
        
        guard expectedChecksums.files.count == checksums.files.count else {
            throw Error("Number of files does not match.")
        }
        
        for (file, checksum) in expectedChecksums.files {
            if checksums.files[file] == nil {
                throw Error("File \(file) is missing.")
            }
            
            if checksums.files[file] != checksum {
                throw Error("Checksum for \(file) does not match.")
            }
        }
    }
    
    private func checksumType(path: String) throws -> ChecksumType {
        let url = URL(filePath: path)
        
        switch url.pathExtension {
        case "md5": return .md5
        case "sha256": return .sha256
        default: throw Error("Unsupported checksum type: \(url.pathExtension).")
        }
    }
}
