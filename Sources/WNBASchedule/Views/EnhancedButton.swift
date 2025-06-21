import SwiftUI

/// Enhanced button component with loading states and improved feedback
struct EnhancedButton: View {
    let title: String
    let style: DesignSystem.ButtonStyle
    let isLoading: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    @Environment(\.colorScheme) 
    var colorScheme
    
    init(
        _ title: String,
        style: DesignSystem.ButtonStyle = .secondary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button {
            if !isLoading {
                action()
            }
        } label: {
            HStack(spacing: DesignSystem.Spacing.xxxs) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else {
                    Text(title)
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(.medium)
                }
            }
            .foregroundColor(style.foregroundColor)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(
                        isPressed ? style.hoverBackgroundColor.opacity(0.8) :
                        isHovered ? style.hoverBackgroundColor : 
                        style.backgroundColor
                    )
            )
            .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.02 : 1.0))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.quick) {
                isHovered = hovering
            }
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(DesignSystem.Animation.quick) {
                isPressed = pressing
            }
        }, perform: {
            // Handle tap
        })
        .animation(DesignSystem.Animation.bouncy, value: isHovered)
        .animation(DesignSystem.Animation.quick, value: isPressed)
    }
}

/// Enhanced icon button with loading and feedback states
struct EnhancedIconButton: View {
    let icon: String
    let title: String?
    let style: DesignSystem.ButtonStyle
    let isLoading: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    @Environment(\.colorScheme) 
    var colorScheme
    
    init(
        icon: String,
        title: String? = nil,
        style: DesignSystem.ButtonStyle = .secondary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button {
            if !isLoading {
                action()
            }
        } label: {
            HStack(spacing: DesignSystem.Spacing.xxxs) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: DesignSystem.ComponentSize.iconSmall))
                }
                
                if let title = title {
                    Text(title)
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(.medium)
                }
            }
            .foregroundColor(style.foregroundColor)
            .padding(.horizontal, title != nil ? DesignSystem.Spacing.sm : DesignSystem.Spacing.xs)
            .padding(.vertical, DesignSystem.Spacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(
                        isPressed ? style.hoverBackgroundColor.opacity(0.8) :
                        isHovered ? style.hoverBackgroundColor : 
                        style.backgroundColor
                    )
            )
            .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.02 : 1.0))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.quick) {
                isHovered = hovering
            }
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(DesignSystem.Animation.quick) {
                isPressed = pressing
            }
        }, perform: {
            // Handle tap
        })
        .animation(DesignSystem.Animation.bouncy, value: isHovered)
        .animation(DesignSystem.Animation.quick, value: isPressed)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        EnhancedButton("Primary Button", style: .primary(color: .blue)) {
            print("Primary tapped")
        }
        
        EnhancedButton("Secondary Button", style: .secondary) {
            print("Secondary tapped")
        }
        
        EnhancedButton("Loading Button", style: .primary(color: .green), isLoading: true) {
            print("Loading tapped")
        }
        
        EnhancedIconButton(icon: "arrow.clockwise", title: "Refresh", style: .primary(color: .orange)) {
            print("Refresh tapped")
        }
        
        EnhancedIconButton(icon: "gear", style: .ghost) {
            print("Settings tapped")
        }
    }
    .padding()
}
