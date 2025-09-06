import SwiftUI

struct AdaptiveGridRowContent<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        #if os(macOS)
        HStack(alignment: .top, spacing: 16) {
            content
        }
        #else
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        #endif
    }
}

#Preview {
    AdaptiveGridRowContent {
        Text("Label")
        Text("Control")
    }
}