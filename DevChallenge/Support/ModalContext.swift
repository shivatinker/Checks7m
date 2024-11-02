//
//  ModalContext.swift
//  DevChallenge
//
//  Created by Andrii Zinoviev on 02.11.2024.
//

import AppKit

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
