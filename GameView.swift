import SwiftUI

struct GameView: View {
    let game: Game

    var body: some View {
        game.view
            .navigationBarTitle(game.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(action: {
                // Add back button action here
            }) {
                Image(systemName: "chevron.left")
                    .imageScale(.large)
            })
    }

}
