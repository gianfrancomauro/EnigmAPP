import SwiftUI

struct PreviewAllFeatures: View {
    @StateObject private var settings = Settings()
    @State private var showSettings = false
    @State private var selectedGame: Game?
    
    let games: [Game] = [
        Game(id: 0, name: "Word Chain", iconName: "link", view: AnyView(WordChainView())),
        Game(id: 1, name: "Sudoku", iconName: "number.square", view: AnyView(SudokuView())),
        Game(id: 2, name: "Rebus", iconName: "puzzlepiece", view: AnyView(Text("Rebus Game"))),
        Game(id: 3, name: "Anagrams", iconName: "textformat.size.larger", view: AnyView(Text("Anagrams Game"))),
        Game(id: 4, name: "Word Search", iconName: "magnifyingglass", view: AnyView(Text("Word Search Game"))),
        Game(id: 5, name: "Cryptograms", iconName: "lock", view: AnyView(Text("Cryptograms Game")))
    ]
    
    var body: some View {
        TabView {
            NavigationView {
                GameGridView()
                    .navigationTitle("EnigmApp")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Games", systemImage: "gamecontroller")
            }
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(games) { game in
                        GameCardView(game: game)
                    }
                }
                .padding()
            }
            .tabItem {
                Label("Cards", systemImage: "square.grid.2x2")
            }
            
            LaunchScreenView()
                .tabItem {
                    Label("Launch", systemImage: "app.badge")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .environmentObject(settings)
    }
}

struct PreviewAllFeatures_Previews: PreviewProvider {
    static var previews: some View {
        PreviewAllFeatures()
    }
}
