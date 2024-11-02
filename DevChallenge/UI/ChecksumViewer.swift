//
//  ChecksumViewer.swift
//  DevChallenge
//
//  Created by Andrii Zinoviev on 02.11.2024.
//

import AppKit
import ChecksumKit
import SwiftUI

@MainActor
final class ChecksumViewer: NSObject, NSWindowDelegate {
    private var currentWindow: ChecksumViewerWindow?
    
    static let shared = ChecksumViewer()
    
    override private init() {}
    
    func viewChecksums(_ file: ChecksumFile, filename: String) {
        if let currentWindow {
            currentWindow.close()
        }
        
        let window = ChecksumViewerWindow(filename: filename, file: file)
        
        window.delegate = self
        self.currentWindow = window
        
        DispatchQueue.main.async {
            window.makeKeyAndOrderFront(nil)
            window.center()
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        self.currentWindow = nil
    }
}

private final class ChecksumViewerWindow: NSWindow {
    private let filename: String
    private let file: ChecksumFile
    private lazy var modalContext = ModalContext(window: self)
    
    init(filename: String, file: ChecksumFile) {
        self.file = file
        self.filename = filename
        
        super.init(
            contentRect: .zero,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        self.contentViewController = NSHostingController(
            rootView: ChecksumViewerContent(file: file)
        )
        
        self.title = filename
        
        self.isReleasedWhenClosed = false
        self.title = "Checksum Viewer"
    }
    
    @objc
    func saveDocument(_ sender: Any) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = self.filename
        
        let result = panel.runModal()
        
        guard result == .OK, let url = panel.url else {
            return
        }
        
        do {
            let data = self.file.makeData()
            try data.write(to: url)
        }
        catch {
            self.modalContext.showError("Failed to save checksum file", error)
        }
    }
    
    @objc
    func saveDocumentAs(_ sender: Any) {
        self.saveDocument(sender)
    }
}

private struct ChecksumViewerContent: View {
    let file: ChecksumFile
    
    var body: some View {
        let rows = self.file.files.sorted(using: KeyPathComparator(\.key.absoluteString)).map {
            TableRow(file: $0.key, checksum: $0.value)
        }
        
        Table(rows) {
            TableColumn("File", value: \.file.path)
            TableColumn("Checksum", value: \.checksum.hexString)
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private struct TableRow: Identifiable {
        var id: URL {
            self.file
        }
        
        let file: URL
        let checksum: Data
    }
}
