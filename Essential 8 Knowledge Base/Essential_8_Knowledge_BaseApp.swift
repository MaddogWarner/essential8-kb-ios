//
//  Essential_8_Knowledge_BaseApp.swift
//  Essential 8 Knowledge Base
//
//  Created by David Warner on 20/5/2026.
//

import SwiftUI

@main
struct Essential_8_Knowledge_BaseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ProgressStore.shared)
        }
    }
}
