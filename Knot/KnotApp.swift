//
//  KnotApp.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/13.
//

import SwiftUI

@main
struct KnotApp: App {
    init() {
        signal(SIGPIPE, SIG_IGN)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
