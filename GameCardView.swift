import SwiftUI

struct GameCardView: View {
    let game: Game
    @State private var isHovered = false
    
    var body: some View {
        NavigationLink(destination: game.view) {
            VStack {
                Image(systemName: game.iconName)
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 100, height: 100)
                    .background(
                        Circle()
                            .fill(Color.purple.opacity(0.8))
                            .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.6), lineWidth: 2)
                    )
                
                Text(game.name)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 10)
            }
            .frame(width: 160, height: 200)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.purple)
                    .shadow(color: .purple.opacity(0.3), radius: 15, x: 0, y: 10)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            HapticManager.shared.playSelection()
        }
    }
}
