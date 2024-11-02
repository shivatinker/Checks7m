//
//  URLExtensionsTests.swift
//  ChecksumKit
//

@testable import ChecksumKit
import XCTest

final class URLExtensionsTests: XCTestCase {
    func testCommonPath() {
        let commonPath = URL.closestCommonPath(for: [
            URL(filePath: "/foo/bar/baz/1.txt"),
            URL(filePath: "/foo/bar/baz/2.txt"),
            URL(filePath: "/foo/4.ff"),
        ])
        
        XCTAssertEqual(commonPath, "/foo")
    }
    
    func testCommonPathRoot() {
        let commonPath = URL.closestCommonPath(for: [
            URL(filePath: "/foo/bar/baz/1.txt"),
            URL(filePath: "/foo/bar/baz/2.txt"),
            URL(filePath: "/guz/4.ff"),
        ])
        
        XCTAssertEqual(commonPath, "/")
    }
    
    func testSingleCommonPath() {
        let commonPath = URL.closestCommonPath(for: [
            URL(filePath: "/foo/bar/baz/1.txt"),
        ])
        
        XCTAssertEqual(commonPath, "/foo/bar/baz")
    }
    
    func testRelativaPath() {
        let path = URL(filePath: "/foo").relativePath(to: URL(filePath: "/foo/bar/baz/1.txt"))
        XCTAssertEqual(path, "bar/baz/1.txt")
    }
    
    func testRelativaPathUpwards() {
        let path = URL(filePath: "/foo/bar/baz").relativePath(to: URL(filePath: "/foo/1.txt"))
        XCTAssertEqual(path, "../../1.txt")
    }
}
