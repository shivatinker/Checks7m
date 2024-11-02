//
//  ChecksumFileTests.swift
//  ChecksumKit
//
//  Created by Andrii Zinoviev on 02.11.2024.
//

import ChecksumKit
import XCTest

final class ChecksumFileTests: XCTestCase {
    func testEncoding() throws {
        let file = ChecksumFile(files: [
            URL(filePath: "/var/tmp/file1.pdf"): Data(hexString: "ab13cd43")!,
            URL(filePath: "/file2.pdf"): Data(hexString: "deadbeef")!,
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
}
