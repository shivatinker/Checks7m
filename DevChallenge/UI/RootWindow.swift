//
//  RootWindow.swift
//  DevChallenge
//
//  Created by Andrii Zinoviev on 02.11.2024.
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
    
    override func responds(to aSelector: Selector!) -> Bool {
        MainActor.assumeIsolated {
            if aSelector == #selector(self.saveDocument(_:)) {
                return self.model.loadedChecksumFile != nil
            }
            
            return super.responds(to: aSelector)
        }
    }
}
