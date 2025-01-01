import SwiftUI

@main
struct EnigmAppApp: App {
    @StateObject private var settings = Settings()
    @State private var showLaunchScreen = true
    // Create the SudokuModel here
    @StateObject private var sudokuModel = SudokuModel(difficulty: .medium) // Add this line

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Inject the SudokuModel into ContentView 
                ContentView()
                    .environmentObject(settings)
                    .environmentObject(sudokuModel) // Add this line

                if showLaunchScreen {
                    LaunchScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showLaunchScreen = false
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
