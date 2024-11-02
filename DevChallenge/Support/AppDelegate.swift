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
        
        window.contentViewController = NSHostingController(
            rootView: RootView(
                RootViewModel()
            )
        )
        
        window.isReleasedWhenClosed = false
        
        DispatchQueue.main.async {
            window.makeKeyAndOrderFront(nil)
            window.setFrameAutosaveName("Main")
            window.setFrame(from: "Main")
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
