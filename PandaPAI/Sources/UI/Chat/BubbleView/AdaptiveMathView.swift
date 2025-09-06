//
//  MathView.swift
//  macai
//
//  Created by Renat on 24.06.2024.
//

import SwiftUI
import SwiftMath

#if os(macOS)
typealias MathViewRepresentable = NSViewRepresentable
#else
typealias MathViewRepresentable = UIViewRepresentable
#endif

struct MathViewSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct MathView: MathViewRepresentable {
    var equation: String
    var fontSize: CGFloat

    #if os(macOS)
    func makeNSView(context: Context) -> MTMathUILabel {
        createMathView()
    }

    func updateNSView(_ view: MTMathUILabel, context: Context) {
        updateMathView(view)
    }
    #else
    func makeUIView(context: Context) -> MTMathUILabel {
        createMathView()
    }

    func updateUIView(_ view: MTMathUILabel, context: Context) {
        updateMathView(view)
    }
    #endif

    private func createMathView() -> MTMathUILabel {
        let view = MTMathUILabel()
        view.font = MTFontManager().termesFont(withSize: fontSize)
        #if os(macOS)
        view.textColor = .textColor
        #else
        view.textColor = .label
        #endif
        view.textAlignment = .left
        view.labelMode = .text
        return view
    }

    private func updateMathView(_ view: MTMathUILabel) {
        view.latex = equation
        view.fontSize = fontSize
        view.setNeedsDisplay(view.bounds)
    }
}

struct AdaptiveMathView: View {
    let equation: String
    let fontSize: CGFloat
    @State private var size: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            MathView(equation: equation, fontSize: fontSize)
                .background(GeometryReader { innerGeometry in
                    Color.clear.preference(key: MathViewSizePreferenceKey.self, value: innerGeometry.size)
                })
                .onPreferenceChange(MathViewSizePreferenceKey.self) { newSize in
                    DispatchQueue.main.async {
                        self.size = newSize
                    }
                }
        }
        .frame(width: size.width, height: size.height)
    }
}

