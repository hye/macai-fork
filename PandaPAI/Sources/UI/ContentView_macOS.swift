//
//  ContentView_macOS.swift
//  macai
//
//  Created by Renat Notfullin on 2025-01-05.
//

import Combine
import CoreData
import Foundation
import SwiftUI
#if os(macOS)
struct ContentView_macOS: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: ChatEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ChatEntity.updatedDate, ascending: false)]
    )
    private var chats: FetchedResults<ChatEntity>

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \APIServiceEntity.addedDate, ascending: false)])
    private var apiServices: FetchedResults<APIServiceEntity>

    @State var selectedChat: ChatEntity?
    @AppStorage("gptToken") var gptToken = ""
    @AppStorage("gptModel") var gptModel = AppConstants.chatGptDefaultModel
    @AppStorage("systemMessage") var systemMessage = AppConstants.chatGptSystemMessage
    @AppStorage("lastOpenedChatId") var lastOpenedChatId = ""
    @AppStorage("apiUrl") var apiUrl = AppConstants.apiUrlChatCompletions
    @AppStorage("defaultApiService") private var defaultApiServiceID: String?
    @StateObject private var previewStateManager = PreviewStateManager()
    @State private var refreshID = UUID()

    @State private var openedChatId: String? = nil
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var searchText = ""
    @State private var isSearchPresented = false

    private var sidebarView: some View {
        ChatListView(selectedChat: $selectedChat, searchText: $searchText)
            .navigationSplitViewColumnWidth(
                min: 180,
                ideal: 220,
                max: 400
            )
    }

    private var detailView: some View {
        Group {
            HSplitView {
                mainContentView
                if previewStateManager.isPreviewVisible {
                    PreviewPane(stateManager: previewStateManager)
                }
            }
        }
        .searchable(text: $searchText, isPresented: $isSearchPresented, placement: .toolbar, prompt: "Search in chat…")
        .onSubmit(of: .search) {
            NotificationCenter.default.post(
                name: NSNotification.Name("FindNext"),
                object: nil
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ActivateSearch"))) { _ in
            NSApp.keyWindow?.makeFirstResponder(nil)
            isSearchPresented = true
        }
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 36 && event.modifierFlags.contains(.shift) && isSearchPresented && !searchText.isEmpty {
                    if let firstResponder = NSApp.keyWindow?.firstResponder as? NSView,
                       String(describing: type(of: firstResponder)).contains("Search") {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("FindPrevious"),
                            object: nil
                        )
                        return nil
                    }
                }
                return event
            }
        }
    }

    private var mainContentView: some View {
        Group {
            if selectedChat != nil {
                ChatView(viewContext: viewContext, chat: selectedChat!, searchText: $searchText)
                    .frame(minWidth: 400)
                    .id(openedChatId)
            } else {
                WelcomeScreen(
                    chatsCount: chats.count,
                    apiServiceIsPresent: apiServices.contains { $0.url != nil },
                    customUrl: apiUrl != AppConstants.apiUrlChatCompletions,
                    openPreferencesView: openPreferencesView,
                    newChat: newChat
                )
                .id(refreshID)
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebarView
        } detail: {
            detailView
        }
        .onAppear(perform: {
            if let lastOpenedChatId = UUID(uuidString: lastOpenedChatId) {
                if let lastOpenedChat = chats.first(where: { $0.id == lastOpenedChatId }) {
                    selectedChat = lastOpenedChat
                }
            }
        })
        .onAppear {
            NotificationCenter.default.addObserver(
                forName: AppConstants.newChatNotification,
                object: nil,
                queue: .main
            ) { _ in
                newChat()
            }
        }
        .navigationTitle("Chats")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Image("logo_\(selectedChat?.apiService?.type ?? "default")")
                    .resizable()
                    .renderingMode(.template)
                    .interpolation(.high)
                    .frame(width: 16, height: 16)

                if let selectedChat = selectedChat {
                    Menu {
                        ForEach(apiServices, id: \.objectID) { apiService in
                            Button(action: {
                                selectedChat.apiService = apiService
                                handleServiceChange(selectedChat, apiService)
                            }) {
                                HStack {
                                    Text(apiService.name ?? "Unnamed API Service")
                                    if selectedChat.apiService == apiService {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }

                        Divider()

                        Text("Current Model: \(selectedChat.gptModel)")
                            .foregroundColor(.secondary)
                    } label: {
                        Text(selectedChat.apiService?.name ?? "Select API Service")
                    }
                }

                Button(action: {
                    isSearchPresented.toggle()
                }) {
                    Image(systemName: "magnifyingglass")
                }

                Button(action: {
                    newChat()
                }) {
                    Image(systemName: "square.and.pencil")
                }

                if #available(macOS 14.0, *) {
                    SettingsLink {
                        Image(systemName: "gear")
                    }
                }
                else {
                    Button(action: {
                        openPreferencesView()
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .onChange(of: scenePhase) { phase in
            print("Scene phase changed: \(phase)")
            if phase == .inactive {
                print("Saving state...")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("APIServiceChanged"))) { _ in
            refreshID = UUID()
        }
        .onChange(of: selectedChat) { oldValue, newValue in
            print("DEBUG: selectedChat changed from \(oldValue?.id.uuidString ?? "nil") to \(newValue?.id.uuidString ?? "nil")")
            if self.openedChatId != newValue?.id.uuidString {
                self.openedChatId = newValue?.id.uuidString
                previewStateManager.hidePreview()

                // Refresh API service data when opening a chat
                if let chat = newValue {
                    if let apiService = chat.apiService {
                        // Refresh the API service object to get latest settings
                        viewContext.refresh(apiService, mergeChanges: true)
                        print("DEBUG: Refreshed API service for chat \(chat.id): imageUploadsAllowed = \(apiService.imageUploadsAllowed)")
                    } else {
                        // Chat has no API service assigned, try to assign the current default
                        print("DEBUG: Chat \(chat.id) has no API service assigned")
                        if let defaultServiceIDString = defaultApiServiceID,
                           let url = URL(string: defaultServiceIDString),
                           let objectID = viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url),
                           let defaultService = try? viewContext.existingObject(with: objectID) as? APIServiceEntity {
                            chat.apiService = defaultService
                            chat.persona = defaultService.defaultPersona
                            chat.gptModel = defaultService.model ?? AppConstants.chatGptDefaultModel
                            chat.systemMessage = chat.persona?.systemMessage ?? AppConstants.chatGptSystemMessage
                            try? viewContext.save()
                            print("DEBUG: Assigned default service to chat \(chat.id)")
                        }
                    }
                }
            }
        }
        .environmentObject(previewStateManager)
    }

    func newChat() {
        let uuid = UUID()
        let newChat = ChatEntity(context: viewContext)

        newChat.id = uuid
        newChat.newChat = true
        newChat.temperature = 0.8
        newChat.top_p = 1.0
        newChat.behavior = "default"
        newChat.newMessage = ""
        newChat.createdDate = Date()
        newChat.updatedDate = Date()
        newChat.systemMessage = systemMessage
        newChat.gptModel = gptModel

        if let defaultServiceIDString = defaultApiServiceID,
            let url = URL(string: defaultServiceIDString),
            let objectID = viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url)
        {

            do {
                let defaultService = try viewContext.existingObject(with: objectID) as? APIServiceEntity
                newChat.apiService = defaultService
                newChat.persona = defaultService?.defaultPersona
                // TODO: Refactor the following code along with ChatView.swift
                newChat.gptModel = defaultService?.model ?? AppConstants.chatGptDefaultModel
                newChat.systemMessage = newChat.persona?.systemMessage ?? AppConstants.chatGptSystemMessage
            }
            catch {
                print("Default API service not found: \(error)")
            }
        }

        do {
            try viewContext.save()
            selectedChat = newChat
        }
        catch {
            print("Error saving new chat: \(error.localizedDescription)")
            viewContext.rollback()
        }
    }

    func openPreferencesView() {
        if #available(macOS 13.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
        else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }

    private func getIndex(for chat: ChatEntity) -> Int {
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            return index
        }
        else {
            fatalError("Chat not found in array")
        }
    }

    private func handleServiceChange(_ chat: ChatEntity, _ newService: APIServiceEntity) {
        if chat.messages.count == 0 {
            if let newDefaultPersona = newService.defaultPersona {
                chat.persona = newDefaultPersona
                if let newSystemMessage = chat.persona?.systemMessage,
                    !newSystemMessage.isEmpty
                {
                    chat.systemMessage = newSystemMessage
                }
            }
        }

        chat.apiService = newService
        chat.gptModel = newService.model ?? AppConstants.chatGptDefaultModel
        chat.objectWillChange.send()
        try? viewContext.save()

        NotificationCenter.default.post(
            name: NSNotification.Name("RecreateMessageManager"),
            object: nil,
            userInfo: ["chatId": chat.id]
        )
    }
}
#endif
