//
//  SceneKitParticlesView.swift
//  macai
//
//  Created by Renat Notfullin on 19.03.2023.
//

import SwiftUI
import SceneKit

#if os(macOS)
typealias SceneViewRepresentable = NSViewRepresentable
typealias SceneColor = NSColor
typealias SceneImage = NSImage
#else
typealias SceneViewRepresentable = UIViewRepresentable
typealias SceneColor = UIColor
typealias SceneImage = UIImage
#endif

struct SceneKitParticlesView: SceneViewRepresentable {
    #if os(macOS)
    func makeNSView(context: Context) -> SCNView {
        createSCNView()
    }

    func updateNSView(_ nsView: SCNView, context: Context) {
    }
    #else
    func makeUIView(context: Context) -> SCNView {
        createSCNView()
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
    }
    #endif

    private func createSCNView() -> SCNView {
        let scnView = SCNView()
        scnView.scene = SCNScene()
        scnView.autoenablesDefaultLighting = false
        scnView.allowsCameraControl = false
        scnView.backgroundColor = SceneColor.clear

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 50)
        scnView.scene?.rootNode.addChildNode(cameraNode)

        // let colors: [SceneColor] = [SceneColor(red: 1, green: 230/255, blue: 140/255, alpha: 1), SceneColor(red: 1, green: 190/255, blue: 95/255, alpha: 0.7), SceneColor(red: 200/255, green: 223/255, blue: 255/255, alpha: 0.8)]
        let colors: [SceneColor] = [SceneColor(red: 34/255, green: 139/255, blue: 34/255, alpha: 1), SceneColor(red: 50/255, green: 205/255, blue: 50/255, alpha: 1), SceneColor(red: 107/255, green: 142/255, blue: 35/255, alpha: 1)]

        let particleNode = SCNNode()

        for color in colors {
            let particleSystem = createWarmColorParticleSystem(color: color)
            particleNode.addParticleSystem(particleSystem)
        }


        scnView.scene?.rootNode.addChildNode(particleNode)

        return scnView
    }
    
    func createWarmColorParticleSystem(color: SceneColor) -> SCNParticleSystem {
        let particleSystem = SCNParticleSystem()

        particleSystem.particleSize = CGFloat.random(in: 0.05...0.2)
        particleSystem.particleImage = SceneImage(named: "Particle")
        particleSystem.particleColor = color
        particleSystem.particleColorVariation = SCNVector4(0.1, 0.1, 0.1, 0.5)
        particleSystem.emitterShape = SCNPlane()
        particleSystem.birthRate = 100
        particleSystem.particleLifeSpan = 10
        particleSystem.particleVelocity = 20
        particleSystem.spreadingAngle = 180
        particleSystem.speedFactor = 0.1
        particleSystem.blendMode = .additive
        return particleSystem
    }

}
