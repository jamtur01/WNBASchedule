import AppKit
import Foundation

// Extension to make NSAttributedString creation cleaner
extension NSAttributedString {
    /// Create an attributed string with the given text and attributes
    static func styled(_ text: String, font: NSFont, color: NSColor, alignment: NSTextAlignment = .left, indent: CGFloat = 0, tabStops: [NSTextTab]? = nil) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.firstLineHeadIndent = indent
        
        if let tabStops = tabStops {
            paragraphStyle.tabStops = tabStops
        }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    /// Create a header style attributed string
    static func header(_ text: String, color: NSColor = NSColor(red: 0.0, green: 0.5, blue: 0.4, alpha: 1.0)) -> NSAttributedString {
        return styled(text, font: .boldSystemFont(ofSize: 14), color: color, alignment: .left, indent: 8)
    }
    
    /// Create a date style attributed string with tab stops for alignment
    static func date(_ text: String) -> NSAttributedString {
        let tabStops = [NSTextTab(textAlignment: .left, location: 180)]
        return styled(text, font: .systemFont(ofSize: 13, weight: .medium), color: .darkGray, alignment: .left, tabStops: tabStops)
    }
    
    /// Create a team style attributed string
    static func team(_ text: String, isWinner: Bool) -> NSAttributedString {
        let color = isWinner ? NSColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 1.0) : NSColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
        return styled(text, font: .boldSystemFont(ofSize: 13), color: color)
    }
    
    /// Create a separator style attributed string
    static func separator(_ text: String = "@") -> NSAttributedString {
        return styled(text, font: .systemFont(ofSize: 13), color: .darkGray)
    }
    
    /// Create a broadcast info style attributed string
    static func broadcast(_ text: String) -> NSAttributedString {
        return styled(text, font: .systemFont(ofSize: 12), color: .darkGray)
    }
    
    /// Create a menu item style attributed string
    static func menuItem(_ text: String, color: NSColor = .darkGray) -> NSAttributedString {
        return styled(text, font: .systemFont(ofSize: 13, weight: .medium), color: color)
    }
    
    /// Create a game row with proper alignment
    static func gameRow(date: String, awayTeam: String, awayScore: Int?, homeTeam: String, homeScore: Int?, homeWon: Bool) -> NSAttributedString {
        let tabStops = [NSTextTab(textAlignment: .left, location: 180)]
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops = tabStops
        
        let mutableString = NSMutableAttributedString()
        
        // Date with tab
        mutableString.append(NSAttributedString(
            string: "\(date)\t",
            attributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: NSColor.darkGray,
                .paragraphStyle: paragraphStyle
            ]
        ))
        
        // Away team with score
        let awayColor = homeWon ? NSColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0) : NSColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 1.0)
        mutableString.append(NSAttributedString(
            string: "\(awayTeam) \(awayScore ?? 0)",
            attributes: [
                .font: NSFont.boldSystemFont(ofSize: 13),
                .foregroundColor: awayColor
            ]
        ))
        
        // Separator
        mutableString.append(NSAttributedString(
            string: " @ ",
            attributes: [
                .font: NSFont.systemFont(ofSize: 13),
                .foregroundColor: NSColor.darkGray
            ]
        ))
        
        // Home team with score
        let homeColor = homeWon ? NSColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 1.0) : NSColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
        mutableString.append(NSAttributedString(
            string: "\(homeTeam) \(homeScore ?? 0)",
            attributes: [
                .font: NSFont.boldSystemFont(ofSize: 13),
                .foregroundColor: homeColor
            ]
        ))
        
        return mutableString
    }
    
    /// Create an upcoming game row with proper alignment
    static func upcomingGameRow(date: String, time: String, awayTeam: String, homeTeam: String, broadcast: String? = nil) -> NSAttributedString {
        let tabStops = [NSTextTab(textAlignment: .left, location: 180)]
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops = tabStops
        
        let mutableString = NSMutableAttributedString()
        
        // Date and time with tab
        mutableString.append(NSAttributedString(
            string: "\(date) at \(time)\t",
            attributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: NSColor.darkGray,
                .paragraphStyle: paragraphStyle
            ]
        ))
        
        // Away team
        mutableString.append(NSAttributedString(
            string: "\(awayTeam)",
            attributes: [
                .font: NSFont.boldSystemFont(ofSize: 13),
                .foregroundColor: NSColor.black
            ]
        ))
        
        // Separator
        mutableString.append(NSAttributedString(
            string: " @ ",
            attributes: [
                .font: NSFont.systemFont(ofSize: 13),
                .foregroundColor: NSColor.darkGray
            ]
        ))
        
        // Home team
        mutableString.append(NSAttributedString(
            string: "\(homeTeam)",
            attributes: [
                .font: NSFont.boldSystemFont(ofSize: 13),
                .foregroundColor: NSColor.black
            ]
        ))
        
        // Broadcast info if available
        if let broadcast = broadcast {
            mutableString.append(NSAttributedString(
                string: " • \(broadcast)",
                attributes: [
                    .font: NSFont.systemFont(ofSize: 12),
                    .foregroundColor: NSColor.darkGray
                ]
            ))
        }
        
        return mutableString
    }
}

// Extension to make NSMutableAttributedString creation and manipulation cleaner
extension NSMutableAttributedString {
    /// Append a styled string
    func append(_ text: String, font: NSFont, color: NSColor) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        self.append(NSAttributedString(string: text, attributes: attributes))
    }
    
    /// Append a date style string
    func appendDate(_ text: String) {
        self.append(NSAttributedString.date(text))
    }
    
    /// Append a team style string
    func appendTeam(_ text: String, isWinner: Bool) {
        self.append(NSAttributedString.team(text, isWinner: isWinner))
    }
    
    /// Append a separator
    func appendSeparator() {
        self.append(NSAttributedString.separator())
    }
    
    /// Append a broadcast info
    func appendBroadcast(_ text: String) {
        self.append(NSAttributedString.broadcast(text))
    }
    
    /// Append a space with the given width
    func appendSpace(_ width: CGFloat = 5) {
        let space = NSAttributedString(string: " ", attributes: [.kern: width])
        self.append(space)
    }
}