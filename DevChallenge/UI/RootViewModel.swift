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
    var checksums: ChecksumFile? { get }
    var isActionEnabled: Bool { get }
    var checksumType: ChecksumType { get set }
    
    func addFiles()
    func removeFiles(_ files: Set<URL>)
    func generateChecksums()
    func loadChecksums()
    func validateChecksums()
}

#if DEBUG

final class MockRootViewModel: RootViewModelProtocol {
    let state: RootViewState = .progress(nil)
    let isActionEnabled = true
    
    let checksums: ChecksumFile? = ChecksumFile(
        files: [
            URL(filePath: "/var/tmp/file1.pdf"): Data(hexString: "abcd1234abcd1234")!,
            URL(filePath: "/var/tmp/file2.pdf"): Data(hexString: "abcd1234abcd1234")!,
            URL(filePath: "/var/tmp/file3.pdf"): Data(hexString: "abcd1234abcd1234")!,
            URL(filePath: "/var/tmp/file4.pdf"): Data(hexString: "abcd1234abcd1234")!,
            URL(filePath: "/var/tmp/file5.pdf"): Data(hexString: "abcd1234abcd1234")!,
        ]
    )
    
    @Published var checksumType: ChecksumType = .sha256
    
    @Published private(set) var files: Set<URL> = [
        URL(filePath: "/var/tmp/file1.pdf"),
        URL(filePath: "/var/tmp/file2.pdf"),
        URL(filePath: "/var/tmp/file3.pdf"),
        URL(filePath: "/var/tmp/file4.pdf"),
        URL(filePath: "/var/tmp/file5.pdf"),
    ]
    
    func addFiles() {}
    
    func removeFiles(_ files: Set<URL>) {}
    
    func generateChecksums() {}
    
    func loadChecksums() {}
    
    func validateChecksums() {}
}

#endif

final class RootViewModel: RootViewModelProtocol {
    private let controller = ChecksumController()
    
    @Published private(set) var state: RootViewState = .ready
    @Published private(set) var files: Set<URL> = []
    
    @Published var checksumType: ChecksumType = .sha256
    
    @Published private(set) var checksumsFileURL: URL?
    @Published private(set) var checksums: ChecksumFile?
    
    var isActionEnabled: Bool {
        if case .progress = self.state {
            return false
        }
        
        return false == self.files.isEmpty
    }
    
    func generateChecksums() {
        precondition(self.isActionEnabled)
        
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
                
//                NSWorkspace.shared.open(url)
                
                self.checksums = try ChecksumFile(data: try Data(contentsOf: url))
                self.checksumsFileURL = url
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
        
        do {
            self.checksums = try ChecksumFile(data: try Data(contentsOf: url))
            self.checksumsFileURL = url
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
        
        self.files.formUnion(panel.urls)
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
