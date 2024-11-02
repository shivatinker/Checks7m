//
//  AppDelegate.swift
//  DevChallenge
//
//  Created by Andrii Zinoviev on 01.11.2024.
//

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        let modalContext = ModalContext(window: window)
        
        window.contentViewController = NSHostingController(
            rootView: RootView(
                RootViewModel(modalContext: modalContext)
            )
        )
        
        window.isReleasedWhenClosed = false
        window.title = "Checks8m"
        
        DispatchQueue.main.async {
            window.makeKeyAndOrderFront(nil)
//            window.setFrameAutosaveName("Main")
//            window.setFrame(from: "Main")
            window.center()
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@MainActor
final class ModalContext {
    private unowned let window: NSWindow
    
    init(window: NSWindow) {
        self.window = window
    }
    
    func showError(_ title: String, _ error: Error) {
        self.showMessage(title, "\(error)", alertStyle: .critical)
    }
    
    func showMessage(_ title: String, _ message: String, alertStyle: NSAlert.Style = .informational) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = alertStyle
        alert.addButton(withTitle: "OK")
            
        alert.beginSheetModal(for: self.window) { response in
            if response == .alertFirstButtonReturn {
                print("OK button clicked")
            }
        }
    }
}
