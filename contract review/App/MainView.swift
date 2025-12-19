//
//  MainView.swift
//  contract review
//
//  Created by Codex on 2025/10/18.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HistoryShellView()
            .environmentObject(appState)
            .environmentObject(appState.historyController)
            .frame(minWidth: 720, minHeight: 520)
            .sheet(isPresented: $appState.isShowingSettings) {
                SettingsSheetView(isPresented: $appState.isShowingSettings)
                    .environmentObject(appState)
            }
    }
}

#Preview {
    MainView()
        .environmentObject(AppState())
}
