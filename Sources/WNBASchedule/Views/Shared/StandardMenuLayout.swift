import SwiftUI

/// Standard layout component for all menu bar views
/// Ensures consistent dimensions and button visibility
struct StandardMenuLayout<Header: View, Content: View, Footer: View>: View {
    let header: Header
    let content: Content
    let footer: Footer
    
    init(
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.header = header()
        self.content = content()
        self.footer = footer()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed header section - 40px
            header
                .frame(height: 40)
                .padding(.horizontal, 12)
            
            Divider()
            
            // Scrollable content section - 515px
            ScrollView(.vertical, showsIndicators: false) {
                content
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .frame(height: 515)
            .clipped()
            
            Divider()
            
            // Fixed footer section - 75px (always visible)
            footer
                .frame(height: 75)
                .padding(.horizontal, 12)
        }
        .frame(width: 320, height: 630)
        .background(.clear)
    }
}

/// Preview support
#if DEBUG
struct StandardMenuLayout_Previews: PreviewProvider {
    static var previews: some View {
        StandardMenuLayout(
            header: {
                Text("Sample Header")
                    .font(.headline)
            },
            content: {
                VStack(spacing: 2) {
                    ForEach(0..<20) { i in
                        HStack {
                            Text("Game \(i)")
                            Spacer()
                            Text("Score")
                        }
                        .padding(.vertical, 4)
                    }
                }
            },
            footer: {
                VStack(spacing: 6) {
                    HStack {
                        Text("Launch at login")
                        Spacer()
                    }
                    HStack {
                        Button("All Teams") { }
                        Button("Refresh") { }
                        Button("Quit") { }
                        Spacer()
                    }
                }
            }
        )
    }
}
#endif
