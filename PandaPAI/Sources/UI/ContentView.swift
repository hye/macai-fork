//
//  ContentView.swift
//  macai
//
//  Created by Renat Notfullin on 11.03.2023.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        #if os(macOS)
        ContentView_macOS()
        #else
        ContentView_iOS()
        #endif
    }
}

struct PreviewPane: View {
    @ObservedObject var stateManager: PreviewStateManager
    @State private var isResizing = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("HTML Preview")
                    .font(.headline)
                Spacer()
                Button(action: { stateManager.hidePreview() }) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .frame(minWidth: 300)

            Divider()

            HTMLPreviewView(htmlContent: stateManager.previewContent)
        }
        .background(Color.primary.opacity(0.05))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    if !isResizing {
                        isResizing = true
                    }
                    let newWidth = max(300, stateManager.previewPaneWidth - gesture.translation.width)
                    stateManager.previewPaneWidth = min(800, newWidth)
                }
                .onEnded { _ in
                    isResizing = false
                }
        )
    }
}

