//
//  RootWindow.swift
//  DevChallenge
//

import AppKit
import SwiftUI

final class RootWindow: NSWindow {
    private var model: RootViewModel!
    
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        let modalContext = ModalContext(window: self)
        
        self.model = RootViewModel(modalContext: modalContext)
        
        self.contentViewController = NSHostingController(rootView: RootView(self.model))
        
        self.isReleasedWhenClosed = false
        self.title = "Check7um by <redacted>"
    }
    
    @objc
    func openDocument(_ sender: Any?) {
        self.model.addFiles()
    }
    
    @objc
    func saveDocument(_ sender: Any?) {
        self.model.saveChecksums()
    }
    
    @objc
    func generateChecksums(_ sender: Any?) {
        self.model.generateChecksums()
    }
    
    @objc
    func validateChecksums(_ sender: Any?) {
        self.model.validateChecksums()
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: // Esc
            self.model.cancel()
            
        default:
            return
        }
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        MainActor.assumeIsolated {
            if aSelector == #selector(self.saveDocument(_:)) {
                return self.model.loadedChecksumFile != nil
            }
            
            if aSelector == #selector(self.generateChecksums(_:)) {
                return self.model.isGenerateEnabled
            }
            
            if aSelector == #selector(self.validateChecksums(_:)) {
                return self.model.isValidateEnabled
            }
            
            return super.responds(to: aSelector)
        }
    }
}
