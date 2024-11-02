//
//  AppDelegate.swift
//  DevChallenge
//

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = RootWindow()
        
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

