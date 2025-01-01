import Foundation
import SwiftUI

struct Game: Identifiable {
    let id: Int
    let name: String
    let iconName: String
    let view: AnyView
}
