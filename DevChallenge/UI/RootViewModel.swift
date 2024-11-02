//
//  RootViewModel.swift
//  DevChallenge
//
//  Created by Andrii Zinoviev on 01.11.2024.
//

import AppKit
import ChecksumKit
import Foundation

enum RootViewState {
    case ready
    case progress(Double?)
    case done(String)
    case error
}

@MainActor
protocol RootViewModelProtocol: ObservableObject {
    var state: RootViewState { get }
    var files: [URL: FileItem] { get }
    var checksumType: ChecksumType { get set }
    
    var loadedChecksumFile: URL? { get }
    
    var isGenerateEnabled: Bool { get }
    var isValidateEnabled: Bool { get }
    
    func addFiles()
    func addFiles(_ urls: [URL])
    func removeFiles(_ files: Set<URL>)
    func generateChecksums()
    func loadChecksums()
    func loadChecksums(_ url: URL)
    func validateChecksums()
    func viewChecksums()
}

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
}

#endif

struct FileItem {
    let isDirectory: Bool
}

final class RootViewModel: RootViewModelProtocol {
    private let controller = ChecksumController()
    
    @Published private(set) var state: RootViewState = .ready
    @Published private(set) var files: [URL: FileItem] = [:]
    
    @Published var checksumType: ChecksumType = .sha256
    
    @Published private(set) var loadedChecksumFile: URL?
    
    private let modalContext: ModalContext
    
    init(modalContext: ModalContext) {
        self.modalContext = modalContext
    }
    
    var isGenerateEnabled: Bool {
        if case .progress = self.state {
            return false
        }
        
        return false == self.files.isEmpty
    }
    
    var isValidateEnabled: Bool {
        self.isGenerateEnabled && self.loadedChecksumFile != nil
    }
    
    func generateChecksums() {
        precondition(self.isGenerateEnabled)
        
        Task { @MainActor in
            do {
                self.state = .progress(nil)
                
                let url = try await self.controller.generateChecksum(
                    for: Array(self.files.keys),
                    type: self.checksumType
                ) { progress in
                    Task { @MainActor in
                        self.state = .progress(progress)
                    }
                }
                
                self.state = .done("Done")
                
                self.loadChecksums(url)
                self.viewChecksums()
            }
            catch {
                self.modalContext.showError("Failed to generate checksums", error)
                self.state = .error
            }
        }
    }
    
    func loadChecksums() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        let response = panel.runModal()
        
        guard response == .OK, let url = panel.url else {
            return
        }
        
        self.loadChecksums(url)
    }
    
    func loadChecksums(_ url: URL) {
        self.loadedChecksumFile = url
    }
    
    func viewChecksums() {
        guard let loadedChecksumFile else {
            preconditionFailure()
        }
        
        do {
            let checksums = try ChecksumFile(data: try Data(contentsOf: loadedChecksumFile))
            ChecksumViewer.shared.viewChecksums(checksums)
        }
        catch {
            print("Failed to load checksums: \(error)")
        }
    }
    
    func addFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        
        let response = panel.runModal()
        
        guard response == .OK, false == panel.urls.isEmpty else {
            return
        }
        
        self.addFiles(panel.urls)
    }
    
    func addFiles(_ urls: [URL]) {
        for url in urls {
            let item = FileItem(
                isDirectory: FileManager.default.isDirectory(url: url)
            )
            
            self.files[url] = item
        }
    }
    
    func validateChecksums() {
        guard let loadedChecksumFile else {
            preconditionFailure()
        }
        
        Task { @MainActor in
            do {
                self.state = .progress(nil)
                
                let result = await self.controller.validateChecksums(
                    for: Array(self.files.keys),
                    checksumFileURL: loadedChecksumFile,
                    progressHandler: { progress in
                        Task { @MainActor in
                            if case .progress = self.state {
                                self.state = .progress(progress)
                            }
                        }
                    }
                )
                
                try result.get()
                self.state = .done("Checksum validated")
                self.modalContext.showMessage("Success", "Checksum matches")
            }
            catch {
                self.state = .error
                self.modalContext.showError("Failed to validate checksums", error)
            }
        }
    }
    
    func removeFiles(_ files: Set<URL>) {
        for file in files {
            self.files[file] = nil
        }
    }
}
