//
//  ContractReviewApp.swift
//  contract review
//
//  Created by Codex on 2025/10/18.
//

import SwiftUI

@main
struct LawTabReviewApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appState)
        }
        .commands {
            CommandGroup(after: .appSettings) {
                Button("设置") {
                    appState.isShowingSettings = true
                }
                .keyboardShortcut(",", modifiers: [.command])
            }
        }
    }
}
