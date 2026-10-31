//
//  ContentView.swift
//  PumpIT
//
//  Created by Reiwa on 09.10.2026.
//

import SwiftUI

struct ContentView: View {
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw: String = AppLanguage.current.rawValue

    private var activeLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .english
    }

    var body: some View {
        MapView()
            .environment(\.locale, activeLanguage.locale)
    }
}

#Preview {
    ContentView()
}
