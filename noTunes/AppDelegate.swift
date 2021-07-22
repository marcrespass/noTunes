//
//  AppDelegate.swift
//  noTunes
//
//  Created by Tom Taylor on 04/01/2017.
//  Copyright © 2017 Twisted Digital Ltd. All rights reserved.
//

import Cocoa
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject {
    let kiTunesName = "com.apple.iTunes"
    let kMusicName = "com.apple.Music"

    @IBOutlet weak var statusMenu: NSMenu!
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    @IBAction func enableMusic(_ sender: NSMenuItem? = nil) {
        guard let button = statusItem.button else { fatalError("Button is nil!") }
        button.image = NSImage(named: "enabled")

        sender?.menu?.items.forEach { $0.state = .off}
        sender?.state = .on
    }

    @IBAction func disableMusic(_ sender: NSMenuItem? = nil) {
        guard let button = statusItem.button else { fatalError("Button is nil!") }
        button.image = NSImage(named: "blocked")

        sender?.menu?.items.forEach { $0.state = .off}
        sender?.state = .on

        self.terminateMusicIfRunning()
    }

    @IBAction func quitClicked(_ sender: NSMenuItem? = nil) {
        NSApplication.shared.terminate(self)
    }

    func createListener() {
        let workspaceNotificationCenter = NSWorkspace.shared.notificationCenter
        workspaceNotificationCenter.addObserver(self, selector: #selector(self.musicWillLaunchNotification(note:)), name: NSWorkspace.willLaunchApplicationNotification, object: nil)
    }
    
    func terminateMusicIfRunning() {
        let apps = NSWorkspace.shared.runningApplications
        for currentApp in apps.enumerated() {
            let runningApp = apps[currentApp.offset]
            
            if runningApp.activationPolicy == .regular {
                if let name = runningApp.localizedName, (runningApp.bundleIdentifier == kiTunesName || runningApp.bundleIdentifier == kMusicName) {
                    self.terminateProcessWith(Int(runningApp.processIdentifier), name)
                }
            }
        }
    }
    
    @objc func musicWillLaunchNotification(note:Notification) {
        // This could be better. This checks the image of the button but we could have a state
        if let button = statusItem.button, button.image == NSImage(named: "blocked"),
           let bundleIdentifier = note.userInfo?["NSApplicationBundleIdentifier"] as? String,
           let processId = note.userInfo?["NSApplicationProcessIdentifier"] as? Int {
            switch bundleIdentifier {
                case kiTunesName:
                    self.terminateProcessWith(processId, bundleIdentifier)
                case kMusicName:
                    self.terminateProcessWith(processId, bundleIdentifier)
                default:break
            }
        }
    }

    func terminateProcessWith(_ processId:Int,_ processName:String) {
        let process = NSRunningApplication.init(processIdentifier: pid_t(processId))
        process?.forceTerminate()
    }
}

extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.statusItem.menu = self.statusMenu
        self.disableMusic(self.statusMenu.items.first)
        self.createListener()
    }
}
