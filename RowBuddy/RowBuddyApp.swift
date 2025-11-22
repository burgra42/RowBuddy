//
//  RowBuddyApp.swift
//  RowBuddy
//
//  Created by Will Olson on 7/15/25.
//

import SwiftUI

@main
struct RowBuddyApp: App {
    @StateObject private var settings = AppSettings.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(colorScheme)
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch settings.colorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil // System
        }
    }
}
