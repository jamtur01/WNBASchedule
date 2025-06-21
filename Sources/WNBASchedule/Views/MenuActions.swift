import SwiftUI
import AppKit
import LaunchAtLogin

// MARK: - Menu Actions Components

/// Bottom action bar for the main menu with team switching and actions
struct MenuActions: View {
    let teamAbbreviation: String
    let teamColor: Color
    let refreshAction: () -> Void
    let changeTeamAction: (String) -> Void
    
    @State private var isRefreshLoading = false
    @Environment(\.colorScheme)
    var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .foregroundColor(ColorManager.adaptiveSeparator(colorScheme: colorScheme))
            
            // Action buttons with compact layout
            VStack(spacing: 6) {
                // Top row: Action buttons
                HStack(spacing: 4) {
                    // "All Teams" button
                    Button {
                        changeTeamAction("ALL")
                    } label: {
                        Text("All Teams")
                            .font(.system(size: 10, weight: .medium))
                            .frame(minWidth: 65)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .background(teamAbbreviation == "ALL" ? teamColor : Color.secondary.opacity(0.2))
                    .foregroundColor(teamAbbreviation == "ALL" ? .white : .primary)
                    .cornerRadius(4)
                    
                    // Refresh button
                    Button {
                        performRefresh()
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 9))
                                .rotationEffect(.degrees(isRefreshLoading ? 360 : 0))
                                .animation(isRefreshLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshLoading)
                            Text("Refresh")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .frame(minWidth: 55)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    .background(teamColor)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .disabled(isRefreshLoading)
                    
                    // Quit button
                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Text("Quit")
                            .font(.system(size: 10, weight: .medium))
                            .frame(minWidth: 35)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .background(Color.secondary.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(4)
                    
                    Spacer()
                }
                
                // Bottom row: Version and Launch at Login
                HStack {
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "app.version".localized, Version.version))
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(ColorManager.adaptiveLightText(colorScheme: colorScheme).opacity(0.6))
                        
                        LaunchAtLogin.Toggle()
                            .font(DesignSystem.Typography.caption)
                            .scaleEffect(0.8)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, DesignSystem.Spacing.sm)
            .padding(.bottom, DesignSystem.Spacing.md)
        }
    }
    
    // MARK: - Private Methods
    
    private func performRefresh() {
        isRefreshLoading = true
        
        // Add haptic feedback for enhanced interaction
        let feedback = NSHapticFeedbackManager.defaultPerformer
        feedback.perform(.alignment, performanceTime: .now)
        
        // Perform the actual refresh
        refreshAction()
        
        // Reset loading state after a short delay to show feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(DesignSystem.Animation.standard) {
                isRefreshLoading = false
            }
        }
    }
}

/// Bottom action bar for the all teams menu
struct AllTeamsMenuActions: View {
    let refreshAction: () -> Void
    
    @State private var isRefreshLoading = false
    @Environment(\.colorScheme)
    var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .foregroundColor(ColorManager.adaptiveSeparator(colorScheme: colorScheme))
            
            // Action buttons with compact layout
            VStack(spacing: 6) {
                // Top row: Action buttons
                HStack(spacing: 4) {
                    // Refresh button
                    Button {
                        performRefresh()
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 9))
                                .rotationEffect(.degrees(isRefreshLoading ? 360 : 0))
                                .animation(isRefreshLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshLoading)
                            Text("Refresh")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .frame(minWidth: 55)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    .background(ColorManager.wnbaBrandColor)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .disabled(isRefreshLoading)
                    
                    // Quit button
                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Text("Quit")
                            .font(.system(size: 10, weight: .medium))
                            .frame(minWidth: 35)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .background(Color.secondary.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(4)
                    
                    Spacer()
                }
                
                // Bottom row: Version and Launch at Login
                HStack {
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "app.version".localized, Version.version))
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(ColorManager.adaptiveLightText(colorScheme: colorScheme).opacity(0.6))
                        
                        LaunchAtLogin.Toggle()
                            .font(DesignSystem.Typography.caption)
                            .scaleEffect(0.8)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, DesignSystem.Spacing.sm)
            .padding(.bottom, DesignSystem.Spacing.md)
        }
    }
    
    // MARK: - Private Methods
    
    private func performRefresh() {
        isRefreshLoading = true
        
        // Add haptic feedback for enhanced interaction
        let feedback = NSHapticFeedbackManager.defaultPerformer
        feedback.perform(.alignment, performanceTime: .now)
        
        // Perform the actual refresh
        refreshAction()
        
        // Reset loading state after a short delay to show feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(DesignSystem.Animation.standard) {
                isRefreshLoading = false
            }
        }
    }
}
