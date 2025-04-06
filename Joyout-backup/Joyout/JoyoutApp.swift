//
//  JoyoutApp.swift
//  Joyout
//
//  Created by Gal Sasson on 03/04/2025.
//

import SwiftUI

@main
struct JoyoutApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            ContentView()
        }
    }
}
