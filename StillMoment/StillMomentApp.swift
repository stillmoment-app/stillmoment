//
//  StillMomentApp.swift
//  Still Moment
//
//  Created by Helmut Zechmann on 26.10.25.
//

import SwiftUI

@main
struct StillMomentApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                // Timer Feature Tab
                NavigationStack {
                    TimerView()
                }
                .tabItem {
                    Label("tab.timer", systemImage: "timer")
                }
                .accessibilityLabel(Text("tab.timer.accessibility"))

                // Guided Meditations Library Tab
                NavigationStack {
                    GuidedMeditationsListView()
                }
                .tabItem {
                    Label("tab.library", systemImage: "music.note.list")
                }
                .accessibilityLabel(Text("tab.library.accessibility"))
            }
        }
    }
}
