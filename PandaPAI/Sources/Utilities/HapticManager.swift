//
//  HapticManager.swift
//  macai
//
//  Created by Kilo Code on 2025-09-05.
//

import CoreHaptics
import Foundation
#if canImport(UIKit)
import UIKit

/// A wrapper for managing haptic feedback that properly handles simulator and device differences
class HapticManager {
    static let shared = HapticManager()

    private var engine: CHHapticEngine?
    private var supportsHaptics: Bool = false

    private init() {
        setupHapticEngine()
    }

    private func setupHapticEngine() {
        // Check if device supports haptics
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

        #if targetEnvironment(simulator)
        // Simulator doesn't support Core Haptics
        supportsHaptics = false
        print("DEBUG: HapticManager - Running on simulator, haptics disabled")
        #else
        print("DEBUG: HapticManager - Device supports haptics: \(supportsHaptics)")
        #endif

        if supportsHaptics {
            do {
                engine = try CHHapticEngine()
                try engine?.start()

                // Handle engine reset
                engine?.resetHandler = { [weak self] in
                    print("DEBUG: HapticManager - Engine reset, restarting...")
                    do {
                        try self?.engine?.start()
                    } catch {
                        print("DEBUG: HapticManager - Failed to restart engine: \(error)")
                    }
                }

                // Handle engine stop
                engine?.stoppedHandler = { [weak self] reason in
                    print("DEBUG: HapticManager - Engine stopped: \(reason)")
                    if reason == .systemError {
                        self?.supportsHaptics = false
                    }
                }

            } catch {
                print("DEBUG: HapticManager - Failed to create haptic engine: \(error)")
                supportsHaptics = false
            }
        }
    }

    /// Play a simple haptic pattern
    func playPattern(_ pattern: CHHapticPattern) {
        guard supportsHaptics, let engine = engine else {
            print("DEBUG: HapticManager - Haptics not supported or engine not available")
            return
        }

        do {
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("DEBUG: HapticManager - Failed to play haptic pattern: \(error)")
        }
    }

    /// Play impact feedback
    func playImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard supportsHaptics else {
            print("DEBUG: HapticManager - Impact feedback not supported")
            return
        }

        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Play notification feedback
    func playNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard supportsHaptics else {
            print("DEBUG: HapticManager - Notification feedback not supported")
            return
        }

        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    /// Play selection feedback
    func playSelection() {
        guard supportsHaptics else {
            print("DEBUG: HapticManager - Selection feedback not supported")
            return
        }

        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    /// Create a simple transient haptic pattern
    func createTransientPattern(intensity: Float = 1.0, sharpness: Float = 1.0) -> CHHapticPattern? {
        guard supportsHaptics else { return nil }

        let hapticDict: [CHHapticPattern.Key: Any] = [
            .pattern: [
                [
                    CHHapticPattern.Key.event: [
                        CHHapticPattern.Key.eventType: CHHapticEvent.EventType.hapticTransient.rawValue,
                        CHHapticPattern.Key.time: 0.0,
                        CHHapticPattern.Key.eventDuration: 0.1,
                        CHHapticPattern.Key.eventParameters: [
                            [
                                CHHapticPattern.Key.parameterID: CHHapticEvent.ParameterID.hapticIntensity.rawValue,
                                CHHapticPattern.Key.parameterValue: intensity
                            ],
                            [
                                CHHapticPattern.Key.parameterID: CHHapticEvent.ParameterID.hapticSharpness.rawValue,
                                CHHapticPattern.Key.parameterValue: sharpness
                            ]
                        ]
                    ] as [CHHapticPattern.Key: Any]
                ]
            ]
        ]

        do {
            return try CHHapticPattern(dictionary: hapticDict)
        } catch {
            print("DEBUG: HapticManager - Failed to create transient pattern: \(error)")
            return nil
        }
    }

    /// Create a simple continuous haptic pattern
    func createContinuousPattern(intensity: Float = 1.0, sharpness: Float = 1.0, duration: Double = 0.5) -> CHHapticPattern? {
        guard supportsHaptics else { return nil }

        let hapticDict: [CHHapticPattern.Key: Any] = [
            .pattern: [
                [
                    CHHapticPattern.Key.event: [
                        CHHapticPattern.Key.eventType: CHHapticEvent.EventType.hapticContinuous.rawValue,
                        CHHapticPattern.Key.time: 0.0,
                        CHHapticPattern.Key.eventDuration: duration,
                        CHHapticPattern.Key.eventParameters: [
                            [
                                CHHapticPattern.Key.parameterID: CHHapticEvent.ParameterID.hapticIntensity.rawValue,
                                CHHapticPattern.Key.parameterValue: intensity
                            ],
                            [
                                CHHapticPattern.Key.parameterID: CHHapticEvent.ParameterID.hapticSharpness.rawValue,
                                CHHapticPattern.Key.parameterValue: sharpness
                            ]
                        ]
                    ] as [CHHapticPattern.Key: Any]
                ]
            ]
        ]

        do {
            return try CHHapticPattern(dictionary: hapticDict)
        } catch {
            print("DEBUG: HapticManager - Failed to create continuous pattern: \(error)")
            return nil
        }
    }

    /// Stop all haptic playback
    func stop() {
        guard supportsHaptics, let engine = engine else { return }

        engine.stop { error in
            if let error = error {
                print("DEBUG: HapticManager - Failed to stop engine: \(error)")
            }
        }
    }

    /// Check if haptics are supported on this device
    var isSupported: Bool {
        return supportsHaptics
    }
}

// Convenience extension for easy haptic feedback
extension HapticManager {
    /// Play a light impact
    static func lightImpact() {
        shared.playImpact(style: .light)
    }

    /// Play a medium impact
    static func mediumImpact() {
        shared.playImpact(style: .medium)
    }

    /// Play a heavy impact
    static func heavyImpact() {
        shared.playImpact(style: .heavy)
    }

    /// Play a soft impact
    static func softImpact() {
        shared.playImpact(style: .soft)
    }

    /// Play a rigid impact
    static func rigidImpact() {
        shared.playImpact(style: .rigid)
    }

    /// Play success notification
    static func success() {
        shared.playNotification(type: .success)
    }

    /// Play warning notification
    static func warning() {
        shared.playNotification(type: .warning)
    }

    /// Play error notification
    static func error() {
        shared.playNotification(type: .error)
    }

    /// Play selection changed
    static func selection() {
        shared.playSelection()
    }
}
#else
class HapticManager {
  static let shared = HapticManager()
  private var engine: CHHapticEngine?
  private var supportsHaptics: Bool = false

  private init() {
      
  }
}
#endif
