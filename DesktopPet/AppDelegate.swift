//
//  AppDelegate.swift
//  DesktopPet
//
//  Created by name space on 10/11/26.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var mousePassThough: MousePassthroughController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        guard let window = NSApplication.shared.windows.first,
              let screen = window.screen ?? NSScreen.main
        else { return }
        
        window.styleMask = [.borderless]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        let screenFrame = screen.visibleFrame
        window.setFrame(screenFrame, display: true)
        
        DispatchQueue.main.async{ [weak self, weak window] in
            guard let self,
                  let window,
                  let ViewController = window.contentViewController as? ViewController
            else { return }
            
            ViewController.presentPetScene()
            
            guard let scene = ViewController.petScene else { return }
            
            self.mousePassThough = MousePassthroughController(window: window, scene: scene)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

