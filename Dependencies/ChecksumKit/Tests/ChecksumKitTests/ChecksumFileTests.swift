//
//  ChecksumFileTests.swift
//  ChecksumKit
//

import ChecksumKit
import XCTest

final class ChecksumFileTests: XCTestCase {
    func testEncoding() throws {
        let file = ChecksumFile(files: [
            "/var/tmp/file1.pdf": Data(hexString: "ab13cd43")!,
            "/file2.pdf": Data(hexString: "deadbeef")!,
        ])
        
        let data = file.makeData()
        
        XCTAssertEqual(String(data: data, encoding: .utf8)!, """
        deadbeef  /file2.pdf
        ab13cd43  /var/tmp/file1.pdf
        
        """)
    }
    
    func testDecoding() throws {
        let data = """
        deadbeef  /file2.pdf
        ab13cd43  /var/tmp/file1.pdf
        
        """.data(using: .utf8)!
        
        let _ = try ChecksumFile(data: data)
    }
    
    func testDecodingWithSpaces() throws {
        let data = """
        deadbeef  /file 2.pdf
        ab13cd43  /var/tmp with spaces/file1.pdf
        
        """.data(using: .utf8)!
        
        let file = try ChecksumFile(data: data)
        
        XCTAssertEqual(file.files, [
            "/var/tmp with spaces/file1.pdf": Data(hexString: "ab13cd43")!,
            "/file 2.pdf": Data(hexString: "deadbeef")!,
        ])
    }
}
