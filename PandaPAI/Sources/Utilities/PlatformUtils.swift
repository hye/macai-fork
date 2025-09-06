//
//  PlatformUtils.swift
//  macai
//
//  Created by Renat Notfullin on 11.03.2023.
//

import SwiftUI

// Platform-specific typealiases
#if os(macOS)
    import AppKit
    public typealias OSViewRepresentable = NSViewRepresentable
    public typealias OSPasteboard = NSPasteboard
public typealias OSImage = NSImage

#else
    import UIKit
    public typealias OSViewRepresentable = UIViewRepresentable
    public typealias OSPasteboard = UIPasteboard
    public typealias OSImage = UIImage
#endif
