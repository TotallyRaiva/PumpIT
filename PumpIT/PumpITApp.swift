//
//  PumpITApp.swift
//  PumpIT
//
//  Created by Reiwa on 09.10.2026.
//

import SwiftUI
import SwiftData

@main
struct PumpITApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: PriceLog.self)
    }
}
