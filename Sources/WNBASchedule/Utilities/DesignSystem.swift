import SwiftUI
import AppKit

/// Professional design system for WNBA Schedule app
/// Provides consistent typography, spacing, colors, and component styling
struct DesignSystem {
    
    // MARK: - Typography Scale
    
    /// Semantic font styles following macOS HIG
    enum Typography {
        /// Large title - 20pt, semibold (app headers, main titles)
        static let largeTitle = Font.system(size: 20, weight: .semibold)
        
        /// Title - 16pt, semibold (section headers, primary titles)
        static let title = Font.system(size: 16, weight: .semibold)
        
        /// Headline - 14pt, semibold (subsection headers, important text)
        static let headline = Font.system(size: 14, weight: .semibold)
        
        /// Body - 13pt, regular (primary content, game info)
        static let body = Font.system(size: 13, weight: .regular)
        
        /// Body emphasis - 13pt, medium (emphasized body text, team names)
        static let bodyEmphasis = Font.system(size: 13, weight: .medium)
        
        /// Body bold - 13pt, semibold (scores, important data)
        static let bodyBold = Font.system(size: 13, weight: .semibold)
        
        /// Callout - 12pt, regular (secondary content, timestamps)
        static let callout = Font.system(size: 12, weight: .regular)
        
        /// Footnote - 11pt, regular (metadata, version info)
        static let footnote = Font.system(size: 11, weight: .regular)
        
        /// Caption - 10pt, regular (fine print, status indicators)
        static let caption = Font.system(size: 10, weight: .regular)
        
        /// Caption 2 - 9pt, regular (tiny details, legal text)
        static let caption2 = Font.system(size: 9, weight: .regular)
    }
    
    // MARK: - Spacing Tokens (4pt Grid System)
    
    /// Consistent spacing values based on 4pt grid
    enum Spacing {
        /// 2pt - Ultra tight spacing
        static let xxxs: CGFloat = 2
        
        /// 4pt - Very tight spacing
        static let xxs: CGFloat = 4
        
        /// 6pt - Tight spacing (between related elements)
        static let xs: CGFloat = 6
        
        /// 8pt - Small spacing (component internal padding)
        static let sm: CGFloat = 8
        
        /// 12pt - Medium spacing (between sections)
        static let md: CGFloat = 12
        
        /// 16pt - Large spacing (major sections)
        static let lg: CGFloat = 16
        
        /// 20pt - Extra large spacing (page margins)
        static let xl: CGFloat = 20
        
        /// 24pt - XXL spacing (major layout gaps)
        static let xxl: CGFloat = 24
        
        /// 32pt - XXXL spacing (page-level margins)
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    
    /// Consistent corner radius values
    enum CornerRadius {
        /// 2pt - Subtle rounding (status indicators)
        static let xs: CGFloat = 2
        
        /// 4pt - Small rounding (buttons, tags)
        static let sm: CGFloat = 4
        
        /// 6pt - Medium rounding (cards, input fields)
        static let md: CGFloat = 6
        
        /// 8pt - Large rounding (major components)
        static let lg: CGFloat = 8
        
        /// 12pt - Extra large rounding (popovers, modals)
        static let xl: CGFloat = 12
    }
    
    // MARK: - Interactive States
    
    /// Button state configurations
    enum ButtonStyle {
        case primary(color: Color)
        case secondary
        case ghost
        case destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary(let color):
                return color
            case .secondary:
                return Color(NSColor.controlBackgroundColor)
            case .ghost:
                return Color.clear
            case .destructive:
                return Color.red
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary:
                return .white
            case .secondary:
                return .primary
            case .ghost:
                return .primary
            case .destructive:
                return .white
            }
        }
        
        var hoverBackgroundColor: Color {
            switch self {
            case .primary(let color):
                return color.opacity(0.8)
            case .secondary:
                return Color(NSColor.controlBackgroundColor).opacity(0.8)
            case .ghost:
                return Color(NSColor.controlBackgroundColor).opacity(0.3)
            case .destructive:
                return Color.red.opacity(0.8)
            }
        }
    }
    
    // MARK: - Shadow Styles
    
    enum Shadow {
        /// Subtle shadow for cards and popovers
        static let subtle = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 4,
            x: 0,
            y: 2
        )
        
        /// Medium shadow for elevated components
        static let medium = ShadowStyle(
            color: Color.black.opacity(0.12),
            radius: 8,
            x: 0,
            y: 4
        )
        
        /// Strong shadow for modals and important overlays
        static let strong = ShadowStyle(
            color: Color.black.opacity(0.16),
            radius: 16,
            x: 0,
            y: 8
        )
    }
    
    // MARK: - Animation Curves
    
    enum Animation {
        /// Quick micro-interactions (hover states)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.1)
        
        /// Standard transitions (state changes)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.2)
        
        /// Smooth transitions (page changes, major state updates)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
        
        /// Bouncy animation for interactive feedback
        static let bouncy = SwiftUI.Animation.interpolatingSpring(
            mass: 0.8,
            stiffness: 80,
            damping: 10,
            initialVelocity: 0
        )
        
        /// Gentle spring for natural movement
        static let gentleSpring = SwiftUI.Animation.interpolatingSpring(
            mass: 1.0,
            stiffness: 100,
            damping: 12,
            initialVelocity: 0
        )
        
        /// Loading animation for continuous states
        static let loading = SwiftUI.Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
    }
    
    // MARK: - Component Sizes
    
    /// Standard component dimensions
    enum ComponentSize {
        /// Button heights
        static let buttonSmall: CGFloat = 24
        static let buttonMedium: CGFloat = 32
        static let buttonLarge: CGFloat = 40
        
        /// Icon sizes
        static let iconSmall: CGFloat = 12
        static let iconMedium: CGFloat = 16
        static let iconLarge: CGFloat = 20
        static let iconXLarge: CGFloat = 24
        
        /// Logo sizes
        static let logoSmall: CGFloat = 16
        static let logoMedium: CGFloat = 24
        static let logoLarge: CGFloat = 32
        
        /// Input field heights
        static let inputSmall: CGFloat = 28
        static let inputMedium: CGFloat = 32
        static let inputLarge: CGFloat = 36
    }
}

// MARK: - Interactive Component Extensions

extension View {
    /// Apply consistent hover effect to interactive elements
    /// - Parameter isHovered: Binding to hover state
    /// - Returns: View with hover animation
    func interactiveHover(_ isHovered: Binding<Bool>) -> some View {
        self
            .scaleEffect(isHovered.wrappedValue ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.quick, value: isHovered.wrappedValue)
            .onHover { hovering in
                isHovered.wrappedValue = hovering
            }
    }
    
    /// Apply enhanced hover effect with bounce animation
    /// - Parameter isHovered: Binding to hover state
    /// - Returns: View with bouncy hover animation
    func interactiveHoverBouncy(_ isHovered: Binding<Bool>) -> some View {
        self
            .scaleEffect(isHovered.wrappedValue ? 1.05 : 1.0)
            .animation(DesignSystem.Animation.bouncy, value: isHovered.wrappedValue)
            .onHover { hovering in
                isHovered.wrappedValue = hovering
            }
    }
    
    /// Apply loading state with pulse animation
    /// - Parameter isLoading: Whether the view is in loading state
    /// - Returns: View with loading animation
    func loadingState(_ isLoading: Bool) -> some View {
        self
            .opacity(isLoading ? 0.6 : 1.0)
            .animation(isLoading ? DesignSystem.Animation.loading : DesignSystem.Animation.standard, value: isLoading)
    }
    
    /// Apply smooth appearance animation
    /// - Parameter isVisible: Whether the view should be visible
    /// - Returns: View with appearance animation
    func smoothAppearance(_ isVisible: Bool) -> some View {
        self
            .opacity(isVisible ? 1.0 : 0.0)
            .scaleEffect(isVisible ? 1.0 : 0.9)
            .animation(DesignSystem.Animation.gentleSpring, value: isVisible)
    }
    
    /// Apply standard button styling with hover states
    /// - Parameters:
    ///   - style: Button style variant
    ///   - isHovered: Binding to hover state
    /// - Returns: Styled button view
    func designSystemButton(
        style: DesignSystem.ButtonStyle,
        isHovered: Binding<Bool>
    ) -> some View {
        self
            .font(DesignSystem.Typography.callout)
            .foregroundColor(style.foregroundColor)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xxs)
            .background(
                isHovered.wrappedValue ? style.hoverBackgroundColor : style.backgroundColor
            )
            .cornerRadius(DesignSystem.CornerRadius.sm)
            .animation(DesignSystem.Animation.quick, value: isHovered.wrappedValue)
            .onHover { hovering in
                isHovered.wrappedValue = hovering
            }
    }
    
    /// Apply card-like styling with subtle shadow
    /// - Parameter colorScheme: Current color scheme for adaptive styling
    /// - Returns: Card-styled view
    func designSystemCard(colorScheme: ColorScheme) -> some View {
        self
            .background(ColorManager.adaptiveCardBackground(colorScheme: colorScheme))
            .cornerRadius(DesignSystem.CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .stroke(
                        ColorManager.adaptiveSeparator(colorScheme: colorScheme).opacity(0.5),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: DesignSystem.Shadow.subtle.color,
                radius: DesignSystem.Shadow.subtle.radius,
                x: DesignSystem.Shadow.subtle.x,
                y: DesignSystem.Shadow.subtle.y
            )
    }
    
    /// Apply section header styling
    /// - Parameter colorScheme: Current color scheme
    /// - Returns: Section header styled view
    func designSystemSectionHeader(colorScheme: ColorScheme) -> some View {
        self
            .font(DesignSystem.Typography.headline)
            .foregroundColor(ColorManager.adaptivePrimaryText(colorScheme: colorScheme))
            .padding(.top, 2)
            .padding(.bottom, 1)
    }
}

// MARK: - Shadow Extension

extension View {
    /// Apply design system shadow
    /// - Parameter shadow: Shadow style to apply
    /// - Returns: View with applied shadow
    func designSystemShadow(_ shadow: DesignSystem.ShadowStyle) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
}

// MARK: - Shadow Helper

extension DesignSystem {
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}
