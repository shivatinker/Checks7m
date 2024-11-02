//
//  MockRootViewModel.swift
//  DevChallenge
//

import ChecksumKit
import Foundation

#if DEBUG

final class MockRootViewModel: RootViewModelProtocol {
    let state: RootViewState = .progress(nil)
    
    let isGenerateEnabled = true
    let isValidateEnabled = true
    
    let loadedChecksumFile: URL? = URL(filePath: "checksum.sha256")
    
    @Published var checksumType: ChecksumType = .sha256
    
    @Published private(set) var files: [URL: FileItem] = [
        URL(filePath: "/var/tmp/file1.pdf"): FileItem(isDirectory: false),
        URL(filePath: "/var/tmp/file2.pdf"): FileItem(isDirectory: false),
        URL(filePath: "/var/tmp/dir1"): FileItem(isDirectory: true),
        URL(filePath: "/var/tmp/file4.pdf"): FileItem(isDirectory: false),
        URL(filePath: "/var/tmp/dir2"): FileItem(isDirectory: true),
    ]
    
    func addFiles() {}
    
    func addFiles(_ urls: [URL]) {}
    
    func removeFiles(_ files: Set<URL>) {}
    
    func generateChecksums() {}
    
    func loadChecksums() {}
    
    func loadChecksums(_ url: URL) {}
    
    func validateChecksums() {}
    
    func viewChecksums() {}
    
    func saveChecksums() {}
    
    func cancel() {}
}

#endif
