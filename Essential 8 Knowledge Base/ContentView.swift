//
//  ContentView.swift
//  Essential 8 Knowledge Base
//
//  Created by David Warner on 20/5/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            HomeView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ProgressStore.shared)
}
