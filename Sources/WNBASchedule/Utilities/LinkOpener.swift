import AppKit
import Foundation

/// Opens external links in the user's default browser.
enum LinkOpener {
    /// Opens the given URL, ignoring `nil` so call sites don't repeat the optional check.
    /// - Parameter url: The URL to open, if any.
    static func open(_ url: URL?) {
        guard let url = url else { return }
        NSWorkspace.shared.open(url)
    }
}
