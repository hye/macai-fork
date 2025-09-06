//
//  macaiApp.swift
//  macai
//
//  Created by Renat Notfullin on 11.03.2023.
//

import SwiftUI
import UserNotifications
import CoreData





class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "macaiDataModel")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }
}

@main
struct macaiApp: App {
    @AppStorage("gptModel") var gptModel: String = AppConstants.chatGptDefaultModel
    @AppStorage("preferredColorScheme") private var preferredColorSchemeRaw: Int = 0
    @StateObject private var store = ChatStore(persistenceController: PersistenceController.shared)

    var preferredColorScheme: ColorScheme? {
        switch preferredColorSchemeRaw {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }
    @Environment(\.scenePhase) private var scenePhase

    let persistenceController = PersistenceController.shared

    init() {
        ValueTransformer.setValueTransformer(
            RequestMessagesTransformer(),
            forName: RequestMessagesTransformer.name
        )

        // Initialize haptic manager to prevent CHHapticPattern warnings
        _ = HapticManager.shared

        DatabasePatcher.applyPatches(context: persistenceController.container.viewContext)
        DatabasePatcher.migrateExistingConfiguration(context: persistenceController.container.viewContext)
    }
var body: some Scene {
    #if os(macOS)
    WindowGroup {
        ContentView()
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .preferredColorScheme(preferredColorScheme)
    }
    .commands {
        CommandMenu("Chat") {
            Button("Find in Chat") {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ActivateSearch"),
                    object: nil
                )
            }
            .keyboardShortcut("f", modifiers: .command)

            Button("Retry Last Message") {
                NotificationCenter.default.post(
                    name: NSNotification.Name("RetryMessage"),
                    object: nil
                )
            }
            .keyboardShortcut("r", modifiers: .command)
        }

        CommandGroup(replacing: .newItem) {
            Button("New Chat") {
                NotificationCenter.default.post(
                    name: AppConstants.newChatNotification,
                    object: nil
                )
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("New Window") {
                // New window functionality for macOS
            }
            .keyboardShortcut("n", modifiers: [.command, .option])
        }

        CommandGroup(after: .sidebar) {
            Button("Toggle Sidebar") {
                // Sidebar toggle functionality for macOS
            }
            .keyboardShortcut("s", modifiers: [.command])
        }
    }
    .onChange(of: scenePhase) { phase in
        if phase == .active {
            if UserDefaults.standard.bool(forKey: "autoCheckForUpdates") {
                    //
            }
        }
    }
    Settings {
        PreferencesView()
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .preferredColorScheme(preferredColorScheme)
    }
    #else
    WindowGroup {
        ContentView()
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .preferredColorScheme(preferredColorScheme)
    }
    #endif
    }
}
