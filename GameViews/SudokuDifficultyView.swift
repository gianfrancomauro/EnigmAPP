import SwiftUI

struct SudokuDifficultyView: View {
    @Binding var difficulty: Difficulty
    var onDifficultySelected: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Select Difficulty")
                .font(.title)
                .padding()

            ForEach(Difficulty.allCases, id: \.self) { level in
                Button(action: {
                    difficulty = level
                    onDifficultySelected()
                }) {
                    Text(level.rawValue.capitalized)
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}
