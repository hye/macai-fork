//
//  TabBackupRestoreView.swift
//  macai
//
//  Created by Renat Notfullin on 11.11.2023.
//

import SwiftUI
import UniformTypeIdentifiers

struct BackupRestoreView: View {
  @ObservedObject var store: ChatStore
  @State private var exportFileURL: URL?
  @State private var showImportPicker = false
  @State private var selectedImportURLs: [URL] = []
  
  var body: some View {
    VStack {
      HStack {
        Text("Chats are exported into plaintext, unencrypted JSON file. You can import them back later.")
          .foregroundColor(.gray)
        Spacer()
      }
      .padding(.bottom, 16)
      
      HStack {
        Text("Export chats history")
        Spacer()
#if os(macOS)
        Button("Export to file...") {
          store.loadFromCoreData { result in
            switch result {
            case .failure(let error):
              fatalError(error.localizedDescription)
            case .success(let chats):
              let encoder = JSONEncoder()
              encoder.outputFormatting = .prettyPrinted
              let data = try! encoder.encode(chats)
              let savePanel = NSSavePanel()
              savePanel.allowedContentTypes = [.json]
              savePanel.nameFieldStringValue = "chats_\(getCurrentFormattedDate()).json"
              savePanel.begin { (result) in
                if result == .OK {
                  do {
                    try data.write(to: savePanel.url!)
                  }
                  catch {
                    print(error)
                  }
                }
              }
            }
          }
        }
#else
        if let fileURL = exportFileURL {
          ShareLink(item: fileURL) {
            Text("Export to file...")
          }
        } else {
          Button("Export to file...") {
            store.loadFromCoreData { result in
              switch result {
              case .failure(let error):
                print("Error loading chats: \(error.localizedDescription)")
              case .success(let chats):
                do {
                  let encoder = JSONEncoder()
                  encoder.outputFormatting = .prettyPrinted
                  let data = try encoder.encode(chats)
                  let fileName = "chats_\(getCurrentFormattedDate()).json"
                  let tempDirectory = FileManager.default.temporaryDirectory
                  let fileURL = tempDirectory.appendingPathComponent(fileName)
                  try data.write(to: fileURL)
                  exportFileURL = fileURL
                } catch {
                  print("Error creating export file: \(error)")
                }
              }
            }
          }
        }
#endif
      }
      
      HStack {
        Text("Import chats history")
        Spacer()
        Button("Import from file...") {
#if os(macOS)
          let openPanel = NSOpenPanel()
          openPanel.allowedContentTypes = [.json]
          openPanel.begin { (result) in
            if result == .OK {
              do {
                let data = try Data(contentsOf: openPanel.url!)
                let decoder = JSONDecoder()
                let chats = try decoder.decode([Chat].self, from: data)
                
                store.saveToCoreData(chats: chats) { result in
                  print("State saved")
                  if case .failure(let error) = result {
                    fatalError(error.localizedDescription)
                  }
                }
                
              }
              catch {
                print(error)
              }
            }
          }
#else
          // On iOS, show document picker
          showImportPicker = true
#endif
        }
      }
    }
    .padding(32)
    #if os(iOS)
        .sheet(isPresented: $showImportPicker) {
            DocumentPickerView(
                selectedURLs: $selectedImportURLs,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false,
                onDocumentPicked: { urls in
                    guard let url = urls.first else {
                        showImportPicker = false
                        return
                    }
                    do {
                        let data = try Data(contentsOf: url)
                        let decoder = JSONDecoder()
                        let chats = try decoder.decode([Chat].self, from: data)

                        store.saveToCoreData(chats: chats) { result in
                            switch result {
                            case .success:
                                print("Chats imported successfully")
                            case .failure(let error):
                                print("Error saving chats: \(error.localizedDescription)")
                                // Could show user alert here
                            }
                        }
                    } catch {
                        print("Error importing chats: \(error)")
                        // Could show user alert here
                    }
                    showImportPicker = false
                },
                onCancel: {
                    showImportPicker = false
                }
            )
        }
    #endif
    }

}
