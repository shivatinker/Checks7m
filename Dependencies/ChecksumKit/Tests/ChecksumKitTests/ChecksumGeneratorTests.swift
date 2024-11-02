//
//  ChecksumGeneratorTests.swift
//  ChecksumKit
//
//  Created by Andrii Zinoviev on 02.11.2024.
//

import ChecksumKit
import XCTest

final class ChecksumGeneratorTests: XCTestCase {
    private static let tempDirectoryPath = NSTemporaryDirectory().appending("/").appending(UUID().uuidString)
    
    func testRecursiveGeneration() throws {
        let files = try self.makeFileList()
        
        let generator = ChecksumGenerator(checksumType: .md5)
        
        let checksum = try generator.generateChecksums(for: files)
        let data = checksum.makeData()
        
        XCTAssertEqual(String(data: data, encoding: .utf8)!, """
        952d2c56d0485958336747bcdd98590d  dir1/file1.txt
        952d2c56d0485958336747bcdd98590d  dir1/file1.txt
        acbd18db4cc2f85cedef654fccc4a4d8  dir2/file2.txt
        """)
    }
    
    private func makeFileList() throws -> [URL] {
        let rootURL = URL(filePath: Self.tempDirectoryPath)
        
        let dir1 = rootURL.appending(path: "dir1")
        try FileManager.default.createDirectory(at: dir1, withIntermediateDirectories: true)
        
        let dir2 = rootURL.appending(path: "dir2")
        try FileManager.default.createDirectory(at: dir2, withIntermediateDirectories: true)
        
        let file1 = dir1.appending(path: "file1.txt")
        FileManager.default.createFile(atPath: file1.path, contents: "Hello!".data(using: .utf8))
        
        let file2 = dir2.appending(path: "file2.txt")
        FileManager.default.createFile(atPath: file2.path, contents: "foo".data(using: .utf8))
        
        return [dir1, file1, file2]
    }
}
