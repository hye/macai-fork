import SwiftUI

struct AdaptiveGridRow<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        #if os(macOS)
        GridRow {
            content
        }
        #else
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        #endif
    }
}

#Preview {
    AdaptiveGridRow {
        Text("Label")
        Text("Control")
    }
}