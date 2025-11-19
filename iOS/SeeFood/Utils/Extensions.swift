import Foundation
import SwiftUI
import UIKit

// MARK: - Date Extensions
extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.second, .minute, .hour, .day], from: self, to: now)

        if let days = components.day, days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else if let seconds = components.second, seconds > 0 {
            return seconds == 1 ? "1 second ago" : "\(seconds) seconds ago"
        } else {
            return "Just now"
        }
    }

    func formatForDisplay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: self)
    }
}

// MARK: - URL Extensions
extension URL {
    func isValidURL() -> Bool {
        let scheme = self.scheme?.lowercased()
        return scheme == "http" || scheme == "https"
    }
}

// MARK: - String Extensions
extension String {
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }

    func trimmed() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - View Extensions
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - Custom Shape for Corner Radius
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Bundle Extensions
extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}

// MARK: - Color Extensions
extension Color {
    static let seeFoodBlue = Color(red: 0.0, green: 0.48, blue: 1.0)
    static let seeFoodGreen = Color(red: 0.0, green: 0.8, blue: 0.4)
    static let seeFoodRed = Color(red: 1.0, green: 0.2, blue: 0.2)
    static let seeFoodGray = Color(red: 0.6, green: 0.6, blue: 0.6)
    static let seeFoodLightGray = Color(red: 0.9, green: 0.9, blue: 0.9)
}