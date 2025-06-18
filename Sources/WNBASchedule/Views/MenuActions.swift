import SwiftUI
import AppKit

// MARK: - Menu Actions Components

/// Bottom action bar for the main menu with team switching and actions
struct MenuActions: View {
    let teamAbbreviation: String
    let teamColor: Color
    let refreshAction: () -> Void
    let changeTeamAction: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            // Menu Actions on a single line with distinct styling
            HStack {
                // Buttons next to each other
                HStack(spacing: 8) {
                    // "All Teams" button
                    Button(
                        action: {
                            changeTeamAction("ALL")
                        },
                        label: {
                            Text("All Teams".localized)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(teamAbbreviation == "ALL" ? .white : ColorManager.wnbaBrandColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    teamAbbreviation == "ALL"
                                        ? ColorManager.wnbaBrandColor
                                        : ColorManager.wnbaBrandColor.opacity(0.15)
                                )
                                .cornerRadius(5)
                        }
                    )
                    .buttonStyle(PlainButtonStyle())

                    // Refresh button - positive action (team color)
                    Button(
                        action: refreshAction,
                        label: {
                            Text("action.refresh".localized)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(teamColor)
                                .cornerRadius(4)
                        }
                    )
                    .buttonStyle(PlainButtonStyle())

                    // Quit button - more subtle (gray)
                    Button(
                        action: {
                            NSApplication.shared.terminate(nil)
                        },
                        label: {
                            Text("action.quit".localized)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.gray)
                                .cornerRadius(4)
                        }
                    )
                    .buttonStyle(PlainButtonStyle())
                }

                Spacer()

                // Version as a small, subtle text on the far right
                Text(String(format: "app.version".localized, Version.version))
                    .font(.system(size: 9))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .frame(minWidth: 320)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }
}

/// Bottom action bar for the all teams menu
struct AllTeamsMenuActions: View {
    let refreshAction: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            // Menu Actions
            HStack {
                HStack(spacing: 8) {
                    Button(
                        action: refreshAction,
                        label: {
                            Text("action.refresh".localized)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(ColorManager.wnbaBrandColor)
                                .cornerRadius(4)
                        }
                    )
                    .buttonStyle(PlainButtonStyle())

                    Button(
                        action: {
                            NSApplication.shared.terminate(nil)
                        },
                        label: {
                            Text("action.quit".localized)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.gray)
                                .cornerRadius(4)
                        }
                    )
                    .buttonStyle(PlainButtonStyle())
                }

                Spacer()

                Text(String(format: "app.version".localized, Version.version))
                    .font(.system(size: 9))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .frame(minWidth: 320)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }
}
