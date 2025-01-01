import SwiftUI

class Settings: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    @Published var volume: Double {
        didSet {
            UserDefaults.standard.set(volume, forKey: "volume")
        }
    }
    
    @Published var vibrationStrength: Int {
        didSet {
            UserDefaults.standard.set(vibrationStrength, forKey: "vibrationStrength")
        }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }
    
    @Published var showTutorials: Bool {
        didSet {
            UserDefaults.standard.set(showTutorials, forKey: "showTutorials")
        }
    }
    
    @Published var difficultyLevel: DifficultyLevel {
        didSet {
            UserDefaults.standard.set(difficultyLevel.rawValue, forKey: "difficultyLevel")
        }
    }
    
    init() {
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        self.volume = UserDefaults.standard.double(forKey: "volume")
        self.vibrationStrength = UserDefaults.standard.integer(forKey: "vibrationStrength")
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        self.showTutorials = UserDefaults.standard.bool(forKey: "showTutorials")
        self.difficultyLevel = DifficultyLevel(rawValue: UserDefaults.standard.integer(forKey: "difficultyLevel")) ?? .medium
    }
    
    func resetToDefaults() {
        isDarkMode = false
        volume = 0.5
        vibrationStrength = 2
        notificationsEnabled = true
        showTutorials = true
        difficultyLevel = .medium
    }
}

enum DifficultyLevel: Int, CaseIterable, Identifiable {
    case easy = 0
    case medium = 1
    case hard = 2
    
    var id: Int { self.rawValue }
    
    var description: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
}
