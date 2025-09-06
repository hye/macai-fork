//
//  ImageEnabledMessageInputView.swift
//  macai
//
//  Created by Renat on 2024-07-15
//

import OmenTextField
import SwiftUI
import UniformTypeIdentifiers

struct MessageInputView: View {
    @Binding var text: String
    @Binding var attachedFiles: [FileAttachment]
    var fileUploadsAllowed: Bool
    var onEnter: () -> Void
    var onAddFile: () -> Void

    @State var frontReturnKeyType = OmenTextField.ReturnKeyType.next
    @State var isFocused: Focus?
    @State var dynamicHeight: CGFloat = 16
    @State var inputPlaceholderText = "Type your prompt here"
    @State var cornerRadius = 20.0
    @State private var isHoveringDropZone = false

    private let maxInputHeight = 160.0
    private let initialInputSize = 16.0
    private let inputPadding = 8.0
    private let lineWidthOnBlur = 2.0
    private let lineWidthOnFocus = 3.0
    private let lineColorOnBlur = Color.gray.opacity(0.5)
    private let lineColorOnFocus = Color.blue.opacity(0.8)
    @AppStorage("chatFontSize") private var chatFontSize: Double = 14.0
  @FocusState private var keyboardFocused: Bool

    private var effectiveFontSize: Double {
        chatFontSize
    }

    enum Focus {
        case focused, notFocused
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(attachedFiles) { attachment in
                        FilePreviewView(attachment: attachment) { index in
                            if let index = attachedFiles.firstIndex(where: { $0.id == attachment.id }) {
                                withAnimation {
                                    attachedFiles.remove(at: index)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 0)
                .padding(.bottom, 8)
            }
            .frame(height: attachedFiles.isEmpty ? 0 : 100)

            HStack(spacing: 8) {
                if fileUploadsAllowed {
                    Button(action: onAddFile) {
                        Image(systemName: "paperclip")
                            .font(.system(size: 16))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Add file")
                }

                ZStack {
                    Text(text == "" ? inputPlaceholderText : text)
                        .font(.system(size: effectiveFontSize))
                        .lineLimit(10)
                        .background(
                            GeometryReader { geometryText in
                                Color.clear
                                    .onAppear {
                                        dynamicHeight = calculateDynamicHeight(using: geometryText.size.height)
                                    }
                                    .onChange(of: geometryText.size) { _,_ in
                                        dynamicHeight = calculateDynamicHeight(using: geometryText.size.height)
                                    }
                            }
                        )
                        .padding(inputPadding)
                        .hidden()

                    OmenTextField(
                        inputPlaceholderText,
                        text: $text,
                        isFocused: $isFocused.equalTo(.focused),
                        returnKeyType: frontReturnKeyType,
                        fontSize: effectiveFontSize,
                        onCommit: {
                            onEnter()
                        }
                    )
                    .focused($keyboardFocused)
                    .padding(inputPadding)
                    .frame(height: dynamicHeight)
                    .background(Color.clear)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                isHoveringDropZone
                                    ? Color.green.opacity(0.8)
                                    : (isFocused == .focused ? lineColorOnFocus : lineColorOnBlur),
                                lineWidth: isHoveringDropZone
                                    ? 6 : (isFocused == .focused ? lineWidthOnFocus : lineWidthOnBlur)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    )
                    .onTapGesture {
                        isFocused = .focused
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    keyboardFocused = false
                }
            }
        }
        .onDrop(of: [.image, .fileURL], isTargeted: $isHoveringDropZone) { providers in
            guard fileUploadsAllowed else { return false }
            return handleDrop(providers: providers)
        }
        .onAppear {
            DispatchQueue.main.async {
                isFocused = .focused
            }
        }
    }

    private func calculateDynamicHeight(using height: CGFloat? = nil) -> CGFloat {
        let newHeight = height ?? dynamicHeight
        return min(max(newHeight, initialInputSize), maxInputHeight) + inputPadding * 2
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var didHandleDrop = false

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { (data, error) in
                    if let url = data as? URL {
                        DispatchQueue.main.async {
                            let attachment = FileAttachment(url: url)
                            withAnimation {
                                attachedFiles.append(attachment)
                            }
                        }
                        didHandleDrop = true
                    }
                }
            }
            else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (data, error) in
                    if let urlData = data as? Data,
                        let url = URL(dataRepresentation: urlData, relativeTo: nil),
                        isValidImageFile(url: url)
                    {
                        DispatchQueue.main.async {
                            let attachment = FileAttachment(url: url)
                            withAnimation {
                                attachedFiles.append(attachment)
                            }
                        }
                        didHandleDrop = true
                    }
                }
            }
        }

        return didHandleDrop
    }

    private func isValidImageFile(url: URL) -> Bool {
        let validExtensions = ["jpg", "jpeg", "png", "webp", "heic", "heif"]
        return validExtensions.contains(url.pathExtension.lowercased())
    }
}

struct FilePreviewView: View {
    @ObservedObject var attachment: FileAttachment
    var onRemove: (Int) -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if attachment.isLoading {
                ProgressView()
                    .frame(width: 80, height: 80)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            else if attachment.isImage, let image = attachment.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
            }
            else {
                // For non-image files, show icon and filename
                VStack(spacing: 4) {
                    Image(systemName: attachment.displayIcon)
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                    Text(attachment.fileName)
                        .font(.caption)
                        .lineLimit(1)
                        .frame(width: 70)
                }
                .frame(width: 80, height: 80)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
            }

            Button(action: {
                onRemove(0)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.6)))
                    .padding(4)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}
