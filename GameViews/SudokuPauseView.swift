import SwiftUI

struct SudokuPauseView: View {
    @ObservedObject var model: SudokuModel
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            Text("Game Paused")
                .font(.title)
                .padding()

            Text("Difficulty: \(model.difficulty.rawValue.capitalized)")
            Text("Mistakes: \(model.mistakeCount)/3")
            Text("Time: \(formatTime(model.elapsedTime))")

            Button(action: {
                model.resumeGame()
                isPresented = false
            }) {
                Text("Resume Game")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(backgroundColor)
        .foregroundColor(textColor)
        .cornerRadius(20)
        .shadow(radius: 10)
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.2) : Color.white
    }

    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
