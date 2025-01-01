import SwiftUI

struct GameGridView: View {
    @EnvironmentObject var settings: Settings
    @State private var isLoading = true
    
    let games: [Game] = [
        Game(id: 0, name: "Word Chain", iconName: "link", view: AnyView(WordChainView())),
        Game(id: 1, name: "Sudoku", iconName: "number.square", view: AnyView(
            SudokuView()
                .environmentObject(SudokuModel(difficulty: .medium))
        )),
        Game(id: 2, name: "Rebus", iconName: "puzzlepiece", view: AnyView(Text("Rebus Game"))),
        Game(id: 3, name: "Anagrams", iconName: "textformat.size.larger", view: AnyView(Text("Anagrams Game"))),
        Game(id: 4, name: "Word Search", iconName: "magnifyingglass", view: AnyView(Text("Word Search Game"))),
        Game(id: 5, name: "Cryptograms", iconName: "lock", view: AnyView(Text("Cryptograms Game")))
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 20) {
                ForEach(games) { game in
                    NavigationLink(destination: game.view) {
                        GameCardView(game: game)
                            .opacity(isLoading ? 0 : 1)
                            .animation(.easeInOut(duration: 0.5).delay(Double(game.id) * 0.1), value: isLoading)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            print("GameGridView appeared, isDarkMode: \(settings.isDarkMode)") // Debug print
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLoading = false
            }
        }
    }
}
