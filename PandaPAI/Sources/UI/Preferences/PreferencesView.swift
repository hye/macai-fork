//
//  PreferencesView.swift
//  macai
//
//  Created by Renat Notfullin on 11.03.2023.
//

import Foundation
import SwiftUI

struct APIRequestData: Codable {
    let model: String
    var messages = [
        [
            "role": "system",
            "content": "You are ChatGPT, a large language model trained by OpenAI. Say hi, if you're there",
        ]
    ]
}

enum PVTabselection: Hashable {
    case general
    case api
    case personas
    case backup
    case dangerzone
}
struct PreferencesView: View {
    @State private var selectedTab: PVTabselection = .general

    @StateObject private var store = ChatStore(persistenceController: PersistenceController.shared)
    @State private var lampColor: Color = .gray

    var body: some View {
        TabView(selection: $selectedTab) {

            Tab("General", systemImage: "gearshape", value: .general) {
                TabGeneralSettingsView()
            }

            Tab("API", systemImage: "network", value: .api) {
                TabAPIServicesView()
            }

            Tab("Personas", systemImage: "person.2", value: .personas) {
                TabAIPersonasView()
            }
            Tab("Backup", systemImage: "externaldrive", value: .backup) {
                BackupRestoreView(store: store)
            }
            Tab("Remove", systemImage: "flame.fill", value: .dangerzone) {
                DangerZoneView(store: store)
            }

        }
        .padding()
        .onAppear(perform: {
            store.saveInCoreData()

            #if os(macOS)
                if let window = NSApp.mainWindow {
                    window.standardWindowButton(.zoomButton)?.isEnabled = false
                }
            #endif
        })
    }
}
