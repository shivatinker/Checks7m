//
//  FileChecksumGeneratorTests.swift
//  ChecksumKit
//

import ChecksumKit
import XCTest

final class FileChecksumGeneratorTests: XCTestCase {
    private static let tempDirectoryPath = NSTemporaryDirectory().appending("/").appending(UUID().uuidString)
                                                                                    
    func testMD5() throws {
        let fileURL = try self.makeTempFile("Hello, DevChallenge!")
        let generator = FileChecksumGenerator(checksumType: .md5)
        let data = try generator.generateChecksum(forFileAt: fileURL)
        XCTAssertEqual(data.hexString, "c6891175ff2684c3603384bc95a5cbd3")
    }
    
    func testSHA256() throws {
        let fileURL = try self.makeTempFile("Hello, DevChallenge!")
        let generator = FileChecksumGenerator(checksumType: .sha256)
        let data = try generator.generateChecksum(forFileAt: fileURL)
        XCTAssertEqual(data.hexString, "27aec15f06ab185da46ee97a7905fd107df66df0853169932afeceec941ac5ff")
    }
    
    override class func setUp() {
        try! FileManager.default.createDirectory(atPath: Self.tempDirectoryPath, withIntermediateDirectories: true)
    }
    
    override class func tearDown() {
        do {
            try FileManager.default.removeItem(atPath: self.tempDirectoryPath)
        }
        catch {
            print("Error removing temp directory: \(error)")
        }
    }
    
    private func makeTempFile(_ contents: String) throws -> URL {
        let url = URL(filePath: Self.tempDirectoryPath).appendingPathComponent(UUID().uuidString)
        
        let data = contents.data(using: .utf8)!
        try data.write(to: url)
        
        return url
    }
}
