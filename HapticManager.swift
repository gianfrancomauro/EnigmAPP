import SwiftUI

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func playSelection() {
        let impact = UISelectionFeedbackGenerator()
        impact.selectionChanged()
    }
    
    func playSuccess() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }
}
