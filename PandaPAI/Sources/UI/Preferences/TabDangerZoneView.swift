//
//  TabDangerZoneView.swift
//  macai
//
//  Created by Renat Notfullin on 11.11.2023.
//

import SwiftUI

struct DangerZoneView: View {
    @ObservedObject var store: ChatStore
    @State private var currentAlert: AlertType?

    enum AlertType: Identifiable {
        case deleteChats, deletePersonas, deleteAPIServices
        var id: Self { self }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(
                    "Here you can remove all chats, AI Assistants and API Services. Use with caution: this action cannot be undone."
                )
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 12) {
                    Button(
                        action: {
                            currentAlert = .deleteChats
                        },
                        label: {
                            Text("Delete all chats")
                        }
                    )
                    Button(action: {
                        currentAlert = .deletePersonas
                    }) {
                        Text("Delete all AI Assistants")
                    }
                    Button(action: {
                        currentAlert = .deleteAPIServices
                    }) {
                        Text("Delete all API Services")
                    }
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding(32)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxHeight: .infinity)
        .alert(item: $currentAlert) { alertType in
            switch alertType {
            case .deleteChats:
                return Alert(
                    title: Text("Delete All Chats"),
                    message: Text("Are you sure you want to delete all chats? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        store.deleteAllChats()
                    },
                    secondaryButton: .cancel()
                )
            case .deletePersonas:
                return Alert(
                    title: Text("Delete All AI Assistants"),
                    message: Text("Are you sure you want to delete all AI Assistants?"),
                    primaryButton: .destructive(Text("Delete")) {
                        store.deleteAllPersonas()
                    },
                    secondaryButton: .cancel()
                )
            case .deleteAPIServices:
                return Alert(
                    title: Text("Delete All API Services"),
                    message: Text("Are you sure you want to delete all API Services?"),
                    primaryButton: .destructive(Text("Delete")) {
                        store.deleteAllAPIServices()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}
