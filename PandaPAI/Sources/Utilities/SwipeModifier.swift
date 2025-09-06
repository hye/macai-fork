//
//  SwipeModifierNew.swift
//  macai
//
//  Created by Renat Notfullin on 2025-01-05.
//

import SwiftUI

#if os(macOS)
import AppKit
#endif

extension View {
    ///
    ///    View modifier to handle swipe gestures.
    ///
    ///    This view modifier is designed to handle swipe gestures on both iOS and macOS.
    ///    On iOS, it uses SwiftUI gestures. On macOS, it supports both mouse/trackpad gestures.
    ///

    func onSwipe(perform action: @escaping (SwipeEvent) -> Void) -> some View {
        modifier(OnSwipe(action: action))
    }

    #if os(macOS)
    func onMouseSwipe(perform action: @escaping (SwipeEvent) -> Void) -> some View {
        modifier(OnMouseSwipe(action: action))
    }
    #endif
}

///
///    Struct containing information for swipe events.
///
public struct SwipeEvent {
    enum SwipeDirection {
        case none, up, down, left, right
    }

    enum Modifier {
        case none, shift, control, option, command
    }

    enum Compass {
        case none, north, south, west, east, northWest, southWest, northEast, southEast
    }

    var directionValue: CGFloat = .zero
    var deltaX: CGFloat = .zero
    var deltaY: CGFloat = .zero
    var location: CGPoint = .zero
    var timestamp: TimeInterval = .nan

    #if os(macOS)
    init(event: NSEvent) {
        guard event.window != nil else { return }
        deltaX = event.scrollingDeltaX
        deltaY = event.scrollingDeltaY
        location = event.locationInWindow
        timestamp = event.timestamp
        directionValue = max(abs(deltaX), abs(deltaY))
    }
    #endif

    init(translation: CGSize, location: CGPoint) {
        self.deltaX = translation.width
        self.deltaY = translation.height
        self.location = location
        self.timestamp = Date().timeIntervalSince1970
        self.directionValue = max(abs(deltaX), abs(deltaY))
    }

    var direction: SwipeDirection {
        let threshold: CGFloat = 10
        if abs(deltaX) > abs(deltaY) {
            if deltaX > threshold { return .right }
            if deltaX < -threshold { return .left }
        } else {
            if deltaY > threshold { return .down }
            if deltaY < -threshold { return .up }
        }
        return .none
    }

    var compass: Compass {
        let threshold: CGFloat = 10
        var directionEastWest: Compass = .none
        var directionNorthSouth: Compass = .none

        if deltaX > threshold { directionEastWest = .east }
        if deltaX < -threshold { directionEastWest = .west }
        if deltaY > threshold { directionNorthSouth = .south }
        if deltaY < -threshold { directionNorthSouth = .north }

        if deltaY == 0 { return directionEastWest }
        if deltaX == 0 { return directionNorthSouth }

        if directionNorthSouth == .north && directionEastWest == .east { return .northEast }
        if directionNorthSouth == .south && directionEastWest == .east { return .southEast }
        if directionNorthSouth == .north && directionEastWest == .west { return .northWest }
        if directionNorthSouth == .south && directionEastWest == .west { return .southWest }

        return .none
    }

    var modifier: Modifier {
        // For SwiftUI gestures, we don't have direct access to modifier keys
        // This would need to be implemented differently if modifier support is needed
        return .none
    }
}

///
///    A ViewModifier for detecting swipe events.
///
private struct OnSwipe: ViewModifier {
    var action: (SwipeEvent) -> Void

    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onEnded { value in
                        let swipeEvent = SwipeEvent(
                            translation: value.translation,
                            location: value.location
                        )
                        action(swipeEvent)
                    }
            )
    }
}

#if os(macOS)
///
///    A ViewModifier for detecting mouse swipe events on macOS.
///
private struct OnMouseSwipe: ViewModifier {
    var action: (SwipeEvent) -> Void

    @State private var insideViewWindow = false
    @State private var monitor: Any? = nil

    func body(content: Content) -> some View {
        content
            .onContinuousHover { phase in
                switch phase {
                case .active:
                    insideViewWindow = true
                case .ended:
                    insideViewWindow = false
                }
            }
            .onAppear {
                monitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { event in
                    if insideViewWindow {
                        let scrollEvent = SwipeEvent(event: event)
                        action(scrollEvent)
                    }
                    return event
                }
            }
            .onDisappear {
                if let monitor = monitor {
                    NSEvent.removeMonitor(monitor)
                }
            }
    }
}
#endif