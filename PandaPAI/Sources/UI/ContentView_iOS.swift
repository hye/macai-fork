//
//  ContentView_iOS.swift
//  macai
//
//  Created by Renat Notfullin on 2025-01-05.
//

import Combine
import CoreData
import Foundation
import SwiftUI

#if os(iOS)
struct ContentView_iOS: View {
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
    @State private var columnVisibility = NavigationSplitViewVisibility.detailOnly
    @State private var searchText = ""
    @State private var isSearchPresented = false
    @State private var showPreferences = false

    private var sidebarView: some View {
        ChatListView(selectedChat: $selectedChat, searchText: $searchText)
    }

    private var detailView: some View {
        Group {
            VStack {
                mainContentView
                if previewStateManager.isPreviewVisible {
                    PreviewPane(stateManager: previewStateManager)
                }
            }
        }
        .searchable(text: $searchText, isPresented: $isSearchPresented, placement: .navigationBarDrawer, prompt: "Search in chat…")
        .onSubmit(of: .search) {
            NotificationCenter.default.post(
                name: NSNotification.Name("FindNext"),
                object: nil
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ActivateSearch"))) { _ in
            isSearchPresented = true
        }
        .toolbar {
            // iPhone toolbar
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    withAnimation {
                        columnVisibility = columnVisibility == .all ? .detailOnly : .all
                    }
                }) {
                    Image(systemName: "sidebar.leading")
                }
            }

            if selectedChat != nil {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    chatToolbarItems
                }
            } else {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        openPreferencesView()
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
    }

    private var mainContentView: some View {
        Group {
            if selectedChat != nil {
                ChatView(viewContext: viewContext, chat: selectedChat!, searchText: $searchText)
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

    private var chatToolbarItems: some View {
        Group {
            Menu {
                ForEach(apiServices, id: \.objectID) { apiService in
                    Button(action: {
                        selectedChat!.apiService = apiService
                        handleServiceChange(selectedChat!, apiService)
                    }) {
                        HStack {
                            Text(apiService.name ?? "Unnamed API Service")
                            if selectedChat!.apiService == apiService {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                Divider()

                Text("Current Model: \(selectedChat!.gptModel)")
                    .foregroundColor(.secondary)
            } label: {
                Image("logo_\(selectedChat!.apiService?.type ?? "default")")
                    .resizable()
                    .renderingMode(.template)
                    .interpolation(.high)
                    .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 16 : 20, height: UIDevice.current.userInterfaceIdiom == .pad ? 16 : 20)
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

            Button(action: {
                openPreferencesView()
            }) {
                Image(systemName: "gear")
            }
        }
    }

    private var welcomeToolbarItems: some View {
        Group {
            Button(action: {
                openPreferencesView()
            }) {
                Image(systemName: "gear")
            }
        }
    }

    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPad: Use NavigationSplitView like macOS
                NavigationSplitView {
                    sidebarView
                } detail: {
                    detailView
                }
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        if selectedChat != nil {
                            chatToolbarItems
                        } else {
                            welcomeToolbarItems
                        }
                    }
                }
                .sheet(isPresented: $showPreferences) {
                  PreferencesView()
                }
            } else {
                // iPhone: Use NavigationStack with slide-out sidebar
                NavigationStack {
                    ZStack {
                        // Main content
                        detailView

                        // Sidebar overlay for iPhone
                        if columnVisibility == .all {
                            Color.black.opacity(0.3)
                                .edgesIgnoringSafeArea(.all)
                                .onTapGesture {
                                    withAnimation {
                                        columnVisibility = .detailOnly
                                    }
                                }

                            HStack {
                                sidebarView
                                    .frame(width: 280)
                                    .background(Color(.systemBackground))
                                    .transition(.move(edge: .leading))
                                Spacer()
                            }
                        }
                    }
//                    .overlay(alignment: .topLeading) {
//                        Button(action: {
//                            withAnimation {
//                                columnVisibility = columnVisibility == .all ? .detailOnly : .all
//                            }
//                        }) {
//                            Image(systemName: "sidebar.leading")
//                                .padding()
//                        }
//                        .padding(.top, 50) // Account for status bar
//                    }
                }
                .sheet(isPresented: $showPreferences) {
                    PreferencesView()
                }
            }
        }
        .onAppear(perform: {
            print("DEBUG: ContentView_iOS appeared, device: \(UIDevice.current.userInterfaceIdiom), selectedChat: \(selectedChat?.id.uuidString ?? "nil")")
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
        .onChange(of: scenePhase) { _,phase in
            print("Scene phase changed: \(phase)")
            if phase == .inactive {
                print("Saving state...")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("APIServiceChanged"))) { _ in
            refreshID = UUID()
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
        showPreferences = true
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
