import SwiftUI

/// Shared base layout for all menu views to ensure consistent sizing and button placement
/// Prevents layout issues by providing a unified structure
struct BaseMenuLayout<Header: View, Content: View, Actions: View>: View {
    let header: Header
    let content: Content
    let actions: Actions
    
    @Environment(\.colorScheme) 
    var colorScheme
    
    init(
        @ViewBuilder 
        header: () -> Header,
        @ViewBuilder 
        content: () -> Content,
        @ViewBuilder 
        actions: () -> Actions
    ) {
        self.header = header()
        self.content = content()
        self.actions = actions()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            // Header section
            header
            
            Divider()
            
            // Main content section
            content
            
            // Spacer to push actions to bottom
            Spacer()
            
            // Actions section (always at bottom)
            actions
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.top, DesignSystem.Spacing.md)
        .padding(.bottom, DesignSystem.Spacing.sm)
        .frame(minWidth: 380, maxWidth: 450, minHeight: 800)
        .background(ColorManager.adaptiveCardBackground(colorScheme: colorScheme))
    }
}

/// Preview support
#if DEBUG
struct BaseMenuLayout_Previews: PreviewProvider {
    static var previews: some View {
        BaseMenuLayout(
            header: {
                Text("Sample Header")
                    .font(DesignSystem.Typography.title)
            },
            content: {
                VStack {
                    Text("Sample Content")
                    Text("More Content")
                }
            },
            actions: {
                HStack {
                    Button("Action 1") { }
                    Button("Action 2") { }
                }
            }
        )
    }
}
#endif
