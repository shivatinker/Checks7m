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
    var isActionEnabled: Bool { get }
    var checksumType: ChecksumType { get set }
    
    func addFiles()
    func removeFiles(_ files: Set<URL>)
    func generateChecksums()
}

#if DEBUG

final class MockRootViewModel: RootViewModelProtocol {
    let state: RootViewState = .progress(nil)
    let isActionEnabled = true
    
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
}

#endif

final class RootViewModel: RootViewModelProtocol {
    private let controller = ChecksumController()
    
    @Published private(set) var state: RootViewState = .ready
    @Published private(set) var files: Set<URL> = []
    
    @Published var checksumType: ChecksumType = .sha256
    
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
                
                NSWorkspace.shared.open(url)
            }
            catch {
                self.state = .error("\(error)")
            }
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
    
    func removeFiles(_ files: Set<URL>) {
        self.files.subtract(files)
    }
}
