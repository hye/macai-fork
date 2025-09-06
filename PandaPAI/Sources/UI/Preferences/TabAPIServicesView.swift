//
//  TabAPIServices.swift
//  macai
//
//  Created by Renat Notfullin on 13.09.2024.
//

import CoreData
import SwiftUI

struct TabAPIServicesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \APIServiceEntity.addedDate, ascending: false)],
        animation: .default
    )
    private var apiServices: FetchedResults<APIServiceEntity>

    @State private var isShowingAddOrEditService = false
    @State private var selectedServiceID: NSManagedObjectID?
    @State private var refreshID = UUID()
    @AppStorage("defaultApiService") private var defaultApiServiceID: String?

    private var isSelectedServiceDefault: Bool {
        guard let selectedServiceID = selectedServiceID else { return false }
        return selectedServiceID.uriRepresentation().absoluteString == defaultApiServiceID
    }

    var body: some View {
        VStack {
            entityListView
                .id(refreshID)

            HStack(spacing: 20) {
                if selectedServiceID != nil {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .keyboardShortcut(.defaultAction)

                    Button(action: onDuplicate) {
                        Label("Duplicate", systemImage: "plus.square.on.square")
                    }
                    .buttonStyle(BorderlessButtonStyle())

                    if !isSelectedServiceDefault {
                        Button(action: {
                            defaultApiServiceID = selectedServiceID?.uriRepresentation().absoluteString
                        }) {
                            Label("Set as Default", systemImage: "star")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    Spacer()

                }
                else {
                    Spacer()
                }
                Button(action: onAdd) {
                    Label("Add New", systemImage: "plus")
                }
            }
        }
        .frame(minHeight: 300)
        .sheet(isPresented: $isShowingAddOrEditService) {
            let selectedApiService = apiServices.first(where: { $0.objectID == selectedServiceID }) ?? nil
            if selectedApiService == nil {
                APIServiceDetailView(viewContext: viewContext, apiService: nil)
            }
            else {
                APIServiceDetailView(viewContext: viewContext, apiService: selectedApiService)
            }

        }
    }

    private var entityListView: some View {
        EntityListView(
            selectedEntityID: $selectedServiceID,
            entities: apiServices,
            detailContent: detailContent,
            onRefresh: refreshList,
            getEntityColor: { _ in nil },
            getEntityName: { $0.name ?? "Untitled Service" },
            getEntityDefault: { $0.objectID.uriRepresentation().absoluteString == defaultApiServiceID },
            getEntityIcon: { "logo_" + ($0.type ?? "default") },
            onEdit: {
                if selectedServiceID != nil {
                    isShowingAddOrEditService = true
                }
            },
            onMove: nil
        )
    }

    private func detailContent(service: APIServiceEntity?) -> some View {
        ScrollView {
            if let service = service {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type of API: \(AppConstants.defaultApiConfigurations[service.type!]?.name ?? "Unknown")")
                    Text("Selected Model: \(service.model ?? "Not specified")")
                    Text("Context size: \(service.contextSize)")
                    Text("Auto chat name generation: \(service.generateChatNames ? "Yes" : "No")")
                    //Text("Stream responses: \(service.useStreamResponse ? "Yes" : "No")")
                    Text("Default AI Assistant: \(service.defaultPersona?.name ?? "None")")
                }
            }
            else {
                Text("Select an API service to view details")
            }
        }
    }

    private func refreshList() {
        refreshID = UUID()
    }

    private func onAdd() {
        selectedServiceID = nil
        isShowingAddOrEditService = true
    }

    private func onDuplicate() {
        if let selectedService = apiServices.first(where: { $0.objectID == selectedServiceID }) {
            let newService = selectedService.copy() as! APIServiceEntity
            newService.name = (selectedService.name ?? "") + " Copy"
            newService.addedDate = Date()

            // Generate new UUID and copy the token
            let newServiceID = UUID()
            newService.id = newServiceID

            if let oldServiceIDString = selectedService.id?.uuidString {
                do {
                    if let token = try TokenManager.getToken(for: oldServiceIDString) {
                        try TokenManager.setToken(token, for: newServiceID.uuidString)
                    }
                }
                catch {
                    print("Error copying API token: \(error)")
                }
            }

            do {
                try viewContext.save()
                refreshList()
            }
            catch {
                print("Error duplicating service: \(error)")
            }
        }
    }

    private func onEdit() {
        isShowingAddOrEditService = true
    }
}

struct APIServiceRowView: View {
    let service: APIServiceEntity

    var body: some View {
        VStack(alignment: .leading) {
            Text(service.name ?? "Untitled Service")
                .font(.headline)
            Text(service.type ?? "Unknown type")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
