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
    case error(String)
}

@MainActor
protocol RootViewModelProtocol: ObservableObject {
    var state: RootViewState { get }
    var files: Set<URL> { get }
    var checksumType: ChecksumType { get set }
    
    var loadedChecksumFile: String? { get }
    
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
    
    let loadedChecksumFile: String? = "checksum.sha256"
    
    @Published var checksumType: ChecksumType = .sha256
    
    @Published private(set) var files: Set<URL> = [
        URL(filePath: "/var/tmp/file1.pdf"),
        URL(filePath: "/var/tmp/file2.pdf"),
        URL(filePath: "/var/tmp/file3.pdf"),
        URL(filePath: "/var/tmp/file4.pdf"),
        URL(filePath: "/var/tmp/file5.pdf"),
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

final class RootViewModel: RootViewModelProtocol {
    private let controller = ChecksumController()
    
    @Published private(set) var state: RootViewState = .ready
    @Published private(set) var files: Set<URL> = []
    
    @Published var checksumType: ChecksumType = .sha256
    
    var loadedChecksumFile: String? {
        self.checksumsFileURL?.lastPathComponent
    }
    
    @Published private(set) var checksumsFileURL: URL?
    
    var isGenerateEnabled: Bool {
        if case .progress = self.state {
            return false
        }
        
        return false == self.files.isEmpty
    }
    
    var isValidateEnabled: Bool {
        self.isGenerateEnabled && self.checksumsFileURL != nil
    }
    
    func generateChecksums() {
        precondition(self.isGenerateEnabled)
        
        Task { @MainActor in
            do {
                self.state = .progress(nil)
                
                let url = try await self.controller.generateChecksum(
                    for: Array(self.files),
                    type: self.checksumType
                ) { progress in
                    Task { @MainActor in
                        self.state = .progress(progress)
                    }
                }
                
                self.state = .done("Done")
                
                self.checksumsFileURL = url
                self.viewChecksums()
            }
            catch {
                self.state = .error("\(error)")
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
        self.checksumsFileURL = url
    }
    
    func viewChecksums() {
        guard let checksumsFileURL else {
            preconditionFailure()
        }
        
        do {
            let checksums = try ChecksumFile(data: try Data(contentsOf: checksumsFileURL))
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
        self.files.formUnion(urls)
    }
    
    func validateChecksums() {
        guard let checksumsFileURL else {
            preconditionFailure()
        }
        
        Task { @MainActor in
            do {
                self.state = .progress(nil)
                
                let result = await self.controller.validateChecksums(
                    for: Array(self.files),
                    checksumFileURL: checksumsFileURL,
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
            }
            catch {
                self.state = .error("\(error)")
            }
        }
    }
    
    func removeFiles(_ files: Set<URL>) {
        self.files.subtract(files)
    }
}
